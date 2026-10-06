require "time"
require "zlib"

module FilesMockServer
  module Simulation
    # The ZIP archive a stored file holds, read as Files.com reads one for zip_list and unzip: its
    # central directory (files-integration-worker's zip_list_contents job) gives each entry's path and
    # uncompressed size, and an entry's data is read from its local header, stored or deflated
    # (zip_extract). What Files.com answers for a file it cannot read this way is Invalid ZIP File
    # (Error.invalid_zip_file); an extraction that meets such a file fails its FileMigration.
    #
    # The simulator reads a subset and refuses the rest as not simulated rather than guess: ZIP64
    # records, entry names that are neither marked UTF-8 nor plain ASCII (the worker decodes those
    # as CP437 or from a Unicode Path extra field), and entry data that does not inflate to exactly
    # its recorded size. Like the worker, it does not check CRC-32s.
    #
    # ZipArchive.build writes the archives file_actions/zip saves (Files#create_zip): file entries
    # only, each deflated or, when that is not smaller, stored, with its CRC-32, sizes and
    # modification time in its local header (no data descriptors) and its name marked UTF-8, as a
    # Java ZipOutputStream writes it. Files.com's compression method and level are deployment
    # settings, so neither the method nor the archive's bytes are a contract; its entries are.
    class ZipArchive
      Entry = Data.define(:path, :compression_method, :flags, :compressed_size, :size, :offset)

      END_OF_DIRECTORY = [ 0x06054b50 ].pack("V").freeze
      ZIP64_LOCATOR = [ 0x07064b50 ].pack("V").freeze
      CENTRAL_HEADER = 0x02014b50
      LOCAL_HEADER = 0x04034b50
      # The worker's bounds (zip-parser.go): files and entries an archive may list.
      MAX_ENTRIES = 10_000
      ENCRYPTED = 0x1
      UTF8 = 0x800
      STORED = 0
      DEFLATED = 8
      # The worker searches the last 66 KiB for the end of central directory record.
      END_SEARCH = 66 * 1024

      # Fixed bytes per entry: its local header (30) and central directory header (46), each followed by its name.
      ENTRY_OVERHEAD = 30 + 46
      END_RECORD_SIZE = 22
      # The earliest modification time an MS-DOS date can hold.
      DOS_EPOCH = Time.utc(1980, 1, 1)

      # A reason the archive cannot be read as Files.com reads one.
      class Invalid < StandardError; end

      attr_reader :entries, :expanded

      # The most bytes #build can write for entries of these [ name, size ]: an entry's data is never
      # longer than its size, because a deflated entry that would be is stored instead.
      def self.size_bound(entries)
        entries.sum { |name, size| ENTRY_OVERHEAD + (2 * name.bytesize) + size } + END_RECORD_SIZE
      end

      # A ZIP archive of `entries`, each [ name, parts (the file's bytes, as strings), modification
      # time (an ISO 8601 UTC string, or nil) ], in this order. Error.not_supported for an archive that
      # would need ZIP64.
      def self.build(entries)
        raise Error.not_supported("A ZIP of more than #{MAX_ENTRIES} entries is not simulated (the reader lists at most #{MAX_ENTRIES})") if entries.size > MAX_ENTRIES

        body = +"".b
        directory = +"".b
        entries.each do |name, parts, mtime|
          raw = name.b
          raise Error.not_supported("A ZIP entry name longer than 65535 bytes is not simulated") if raw.bytesize > 0xffff

          size = parts.sum(&:bytesize)
          crc = parts.reduce(Zlib.crc32) { |sum, part| Zlib.crc32(part, sum) }
          method, data = compressed(parts, size)
          time, date = dos_time(mtime)
          offset = body.bytesize
          raise Error.not_supported("A ZIP needing ZIP64 (an entry or archive past 4 GiB) is not simulated") if size > 0xffffffff || offset + data.bytesize > 0xffffffff

          body << [ LOCAL_HEADER, 20, UTF8, method, time, date, crc, data.bytesize, size, raw.bytesize, 0 ].pack("VvvvvvVVVvv") << raw << data
          directory << [ CENTRAL_HEADER, 20, 20, UTF8, method, time, date, crc, data.bytesize, size, raw.bytesize, 0, 0, 0, 0, 0, offset ].pack("VvvvvvvVVVvvvvvVV") << raw
        end
        start = body.bytesize
        body << directory << [ 0x06054b50, 0, 0, entries.size, entries.size, directory.bytesize, start, 0 ].pack("VvvvvVVv")
      end

      # [ method, data ]: the parts deflated, or stored when deflating does not make them smaller.
      def self.compressed(parts, size)
        deflater = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
        deflated = +"".b
        parts.each { |part| deflated << deflater.deflate(part) }
        deflated << deflater.finish
        deflated.bytesize < size ? [ DEFLATED, deflated ] : [ STORED, parts.join.b ]
      ensure
        deflater&.close
      end

      # [ MS-DOS time, MS-DOS date ] for an ISO 8601 UTC time, clamped to the years a DOS date holds.
      def self.dos_time(mtime)
        at = (Time.iso8601(mtime).utc if mtime)
        at = DOS_EPOCH if at.nil? || at < DOS_EPOCH
        at = Time.utc(2107, 12, 31, 23, 59, 58) if at.year > 2107
        [ (at.hour << 11) | (at.min << 5) | (at.sec / 2), ((at.year - 1980) << 9) | (at.month << 5) | at.day ]
      rescue ArgumentError
        dos_time(nil)
      end
      private_class_method :compressed, :dos_time

      # Raises Invalid for what Files.com refuses, and Error.not_supported for what is not simulated.
      def initialize(bytes)
        @bytes = bytes.b
        raise Invalid, "the zip archive is empty" if @bytes.empty?

        @entries = read_directory
        # Bytes this archive has produced for its entries' data, including a refused inflate chunk.
        @expanded = 0
      end

      # The entry's bytes, or Invalid or Error.not_supported as the extraction fails. A caller admits
      # the entry's recorded size before asking for its data: the data never grows past that size, and
      # an entry that would is refused once the output passes it, having produced at most one zlib
      # output chunk (16 KiB) more, whatever the archive's sizes claim.
      def data(entry)
        signature, _version, flags, method, _time, _date, _crc, _compressed, _size, name_length, extra_length = @bytes.unpack("VvvvvvVVVvv", offset: entry.offset)
        raise Invalid, "entry #{entry.path} has no local header" unless signature == LOCAL_HEADER
        raise Invalid, "entry #{entry.path} is encrypted" if flags.anybits?(ENCRYPTED)
        raise Invalid, "unsupported compression method #{method} (only STORED=0 and DEFLATE=8 are supported)" unless [ STORED, DEFLATED ].include?(method)

        start = entry.offset + 30 + name_length + extra_length
        raise Invalid, "entry #{entry.path} extends outside the archive" if start + entry.compressed_size > @bytes.bytesize

        mismatch = Error.not_supported("An entry whose data does not match its recorded size (#{entry.path}) is not simulated")
        raise mismatch if method == STORED && entry.compressed_size != entry.size

        compressed = @bytes.byteslice(start, entry.compressed_size)
        bytes = method == STORED ? compressed : inflate(compressed, entry.size)
        raise mismatch unless bytes&.bytesize == entry.size

        @expanded += bytes.bytesize if method == STORED
        bytes
      end

      private

      def read_directory
        search_from = [ @bytes.bytesize - END_SEARCH, 0 ].max
        at = @bytes.rindex(END_OF_DIRECTORY, @bytes.bytesize - 22) if @bytes.bytesize >= 22
        raise Invalid, "zip end of central directory record not found" unless at && at >= search_from

        _, disk, directory_disk, disk_records, records, size, start = @bytes.unpack("VvvvvVV", offset: at)
        zip64 = records == 0xffff || size == 0xffffffff || start == 0xffffffff || (at >= 20 && @bytes.byteslice(at - 20, 4) == ZIP64_LOCATOR)
        raise Error.not_supported("ZIP64 archives are not simulated") if zip64
        raise Invalid, "multi-disk archives are not supported" unless disk.zero? && directory_disk.zero? && disk_records == records
        raise Invalid, "central directory offset is outside the archive" if start + size > at
        raise Invalid, "more than #{MAX_ENTRIES} entries" if records > MAX_ENTRIES

        entries = []
        offset = start
        while offset < start + size
          raise Invalid, "invalid central directory file header signature" unless offset + 46 <= start + size && @bytes.unpack1("V", offset:) == CENTRAL_HEADER

          flags, method, _time, _date, _crc, compressed, uncompressed, name_length, extra_length, comment_length = @bytes.unpack("vvvvVVVvvv", offset: offset + 8)
          local = @bytes.unpack1("V", offset: offset + 42)
          ending = offset + 46 + name_length + extra_length + comment_length
          raise Invalid, "central directory entry extends past the directory" if ending > start + size

          path = name(@bytes.byteslice(offset + 46, name_length), flags)
          raise Invalid, "entry path is required" if path.empty?
          raise Invalid, "entry #{path} is encrypted" if flags.anybits?(ENCRYPTED)
          raise Invalid, "entry #{path} has a header offset outside the archive" if local + 30 > start

          entries << Entry.new(path:, compression_method: method, flags:, compressed_size: compressed, size: uncompressed, offset: local)
          raise Invalid, "more than #{MAX_ENTRIES} entries" if entries.size > MAX_ENTRIES

          offset = ending
        end
        raise Invalid, "central directory record count mismatch: expected #{records}, got #{entries.size}" unless entries.size == records

        entries
      end

      def name(raw, flags)
        text = raw.dup.force_encoding(Encoding::UTF_8)
        return text if flags.anybits?(UTF8) && text.valid_encoding?
        return text if raw.ascii_only?

        raise Error.not_supported("ZIP entry names that are not marked UTF-8 and are not ASCII (CP437 or Unicode Path extra field names) are not simulated")
      end

      # The inflated data, or nil once it would pass `size`. zlib hands the output over a chunk at a
      # time (16 KiB at most), and the first chunk that would pass `size` ends the inflation before it
      # is kept, so an entry whose data is longer than recorded is refused without expanding further;
      # a short one inflates to fewer bytes.
      def inflate(compressed, size)
        inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
        output = +"".b
        catch(:longer) do
          inflater.inflate(compressed) do |chunk|
            @expanded += chunk.bytesize
            throw :longer if output.bytesize + chunk.bytesize > size

            output << chunk
          end
          output
        end
      rescue Zlib::Error => e
        raise Invalid, "entry data is not valid deflate data (#{e.message})"
      ensure
        inflater&.close
      end
    end
  end
end
