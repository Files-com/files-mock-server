module FilesMockServer
  module Simulation
    # Files and their bytes, held in simulator memory. A known-size upload begins with
    # files.begin_upload, sends each part's bytes to the upload URL it returns, and becomes the file's
    # new version when files.finalize_upload has checked every listed part. files.download returns a
    # URL for that version, which sends the whole file or a single byte range.
    #
    # Refs and URLs belong to one simulator instance, reset epoch, and upload or file version. Paths are
    # names in a flat in-memory namespace, never paths on the host. All file content held in memory is
    # counted against FILES_MOCK_MAX_TRANSFER_BYTES: stored parts, current versions, part bodies still
    # being read, and replaced versions that a download is still sending. That count spans resets,
    # because such a download may outlive the state it started in.
    #
    # Methods run under the App's lock. A download body takes the same lock when Rack closes it.
    class Files
      # Parameters each operation models. Any other parameter the schema declares for the operation is
      # refused as not simulated. A declared name such as "etags[part]" is a member of the "etags" array.
      MODELED_PARAMS = {
        "files.begin_upload" => %w[path mkdir_parents part ref size with_direct_connection_info],
        "files.finalize_upload" => %w[path action etags mkdir_parents provided_mtime ref size with_direct_connection_info],
        "files.download" => %w[path with_direct_connection_info],
        "files.metadata" => %w[path],
      }.freeze
      # Advertised size of each upload part, lowered to FILES_MOCK_MAX_BODY_BYTES when that is smaller.
      # Clients may send parts of any size; only the body limit bounds them.
      PARTSIZE = 5 * 1024 * 1024
      # Advertised to clients: send one part at a time, in order, and send a failed part again. The
      # simulator does not enforce the order or one-at-a-time sending; finalize joins parts by number.
      UPLOAD_PART_PROFILE = { "http_method" => "PUT", "parallel_parts" => false, "retry_parts" => true }.freeze
      MAX_UPLOADS = 64
      MAX_PARTS = 64
      # How far ahead an upload part's `expires` is set. The simulator does not enforce it.
      UPLOAD_URL_LIFETIME = 15 * 60

      Upload = Struct.new(:id, :path, :parts) # parts: part number => Part
      Part = Data.define(:bytes, :etag)
      # A part body, counted against the transfer byte limit from before it is read until it is stored or released.
      Received = Struct.new(:reserved, :bytes, :sha256, :stored)

      # One finalized version of a file. Its parts are frozen strings that downloads share. It stays
      # counted against the transfer byte limit while it is current or a download is sending it.
      class Version
        attr_reader :path, :number, :parts, :size, :sha256, :mtime, :provided_mtime
        attr_accessor :current, :readers

        def initialize(path, number, parts, provided_mtime)
          @path = path
          @number = number
          @parts = parts
          @size = parts.sum(&:bytesize)
          @sha256 = parts.each_with_object(Digest::SHA256.new) { |part, digest| digest << part }.hexdigest
          @mtime = Time.now.utc.strftime("%FT%TZ")
          @provided_mtime = provided_mtime
          @current = true
          @readers = 0
        end
      end

      # A Rack body that sends bytes first..last of a version in slices of at most SLICE bytes, so a
      # download copies little beyond the stored parts it shares.
      class Download
        SLICE = 64 * 1024

        def initialize(version, first, last, &on_close)
          @version = version
          @first = first
          @last = last
          @on_close = on_close
        end

        def bytesize
          @last - @first + 1
        end

        def each
          offset = 0
          @version.parts.each do |part|
            from = [ @first - offset, 0 ].max
            to = [ @last - offset, part.bytesize - 1 ].min
            from.step(to, SLICE) { |start| yield part.byteslice(start, [ SLICE, to - start + 1 ].min) }
            offset += part.bytesize
          end
        end

        def close
          on_close, @on_close = @on_close, nil
          on_close&.call
        end
      end

      attr_reader :partsize, :bytes_in_use

      def initialize(schema, limits:, instance:, lock:)
        operations = schema.fetch("operations")
        @declared = MODELED_PARAMS.to_h { |operation, _| [ operation, operations.fetch(operation).fetch("params") ] }
        require_modeled_params
        @file_fields = schema.fetch("entities").fetch("files")
        @part_fields = schema.fetch("entities").fetch("file_upload_parts")
        @paths = PathComparison.shared
        @partsize = [ PARTSIZE, limits.max_body_bytes ].min
        @max_files = limits.max_records
        @max_bytes = limits.max_transfer_bytes
        @bytes_in_use = 0
        @instance = instance
        @lock = lock
      end

      # Returns [ upload, FileUploadPart ]. Without a ref it starts a new upload at part 1, ignoring any
      # part number as the API does; with a ref and part it returns that part of the existing upload.
      def begin_upload(state, path, params, origin)
        values = accepted("files.begin_upload", path, params)
        if values.key?("ref")
          raise Error.not_supported("begin_upload with a ref but no part is not simulated") unless values.key?("part")

          upload = open_upload(state, values["ref"], path)
          part = values["part"]
          check_part_number(part)
        else
          check_namespace(state, path)
          raise Error.limit_exceeded(409, "The simulator already holds #{MAX_UPLOADS} unfinished uploads; finalize them or reset") if state.uploads.size >= MAX_UPLOADS

          upload = Upload.new(state.last_upload_id += 1, path, {})
          state.uploads[upload.id] = upload
          part = 1
        end
        [ upload, upload_part(state, upload, part, origin) ]
      end

      # Counts a part body of up to `size` bytes against the transfer byte limit before it is read.
      def reserve(size)
        raise Error.limit_exceeded(409, "Holding #{size} more bytes would pass the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{@bytes_in_use} are in use") if @bytes_in_use + size > @max_bytes

        @bytes_in_use += size
        Received.new(size, nil, nil, false)
      end

      def release(received)
        @bytes_in_use -= received.reserved unless received.stored
      end

      # Stores a part's bytes. Sending a stored part again with the same bytes returns the stored part;
      # different bytes are refused rather than replacing it.
      def store_part(state, target, received)
        upload = state.uploads[target["upload"]]
        raise Error.file_upload_not_found(target["ref"]) unless upload && target["part"]

        number = target["part"]
        check_part_number(number)
        if (stored = upload.parts[number])
          raise Error.not_supported("Part #{number} is already stored with different bytes; the simulator does not replace stored parts") unless stored.etag == received.sha256

          return stored
        end

        @bytes_in_use -= received.reserved - received.bytes.bytesize
        received.stored = true
        upload.parts[number] = Part.new(received.bytes, received.sha256)
      end

      # Checks every listed part, then makes them, in part number order, the file's new version in one
      # step. Returns [ status, upload, version ]. A failure leaves the upload open and the file's
      # current version in place.
      def finalize_upload(state, path, params)
        values = accepted("files.finalize_upload", path, params)
        raise Error.bad_request("action is missing") unless values.key?("action")
        raise Error.not_supported("Only action=end, which finalizes an upload, is simulated for POST /files/{path}") unless values["action"] == "end"
        raise Error.request_params_required("ref") if values["ref"].to_s.empty?

        upload = open_upload(state, values["ref"], path)
        parts = listed_parts(values["etags"], upload).map { |number| upload.parts.fetch(number).bytes }
        size = parts.sum(&:bytesize)
        raise Error.request_params_invalid("size is #{values["size"]}, but the listed parts hold #{size} bytes") if values.key?("size") && values["size"] != size

        check_namespace(state, path)
        previous = state.files[path]
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_files} files (FILES_MOCK_MAX_RECORDS)") if previous.nil? && state.files.size >= @max_files

        version = Version.new(path, state.commits += 1, parts.freeze, values["provided_mtime"])
        state.files[path] = version
        state.uploads.delete(upload.id)
        retire(previous) if previous
        [ previous ? 200 : 201, upload, version ]
      end

      # Returns [ current version, download URL for exactly that version ].
      def download(state, path, params, origin)
        accepted("files.download", path, params)
        version = current_version(state, path)
        [ version, "#{origin}#{TRANSFER_PREFIX}/download/#{Token.encode("download", @instance, state.epoch, version.number)}" ]
      end

      def metadata(state, path, params)
        accepted("files.metadata", path, params)
        current_version(state, path)
      end

      # A version's File object, with its download URL when it has one.
      def present(version, download_uri = nil)
        {
          "path" => version.path, "display_name" => version.path.split("/").last, "type" => "file", "size" => version.size,
          "mtime" => version.mtime, "provided_mtime" => version.provided_mtime, "download_uri" => download_uri,
        }.compact.slice(*@file_fields)
      end

      # The current version with the given number, or nil.
      def version_by_number(state, number)
        state.files.each_value.find { |version| version.number == number }
      end

      # Returns [ version, Rack response ] sending the version a download URL names: the whole file, or
      # one byte range. The URL of a replaced version is refused, but a response already sending it
      # finishes from the same bytes, which stay counted until Rack closes the body.
      def send_version(state, target, range_header)
        number = target["version"]
        version = version_by_number(state, number)
        raise Error.download_source_changed if version.nil? && number && number <= state.commits
        raise Error.not_found unless version

        range = byte_range(range_header, version.size)
        first, last = range || [ 0, version.size - 1 ]
        headers = { "content-type" => "application/octet-stream", "content-length" => (last - first + 1).to_s, "accept-ranges" => "bytes", "etag" => %("#{version.sha256}") }
        headers["content-range"] = "bytes #{first}-#{last}/#{version.size}" if range
        version.readers += 1
        [ version, [ range ? 206 : 200, headers, Download.new(version, first, last) { @lock.synchronize { close_reader(version) } } ] ]
      end

      def readiness(state)
        {
          "upload_parts" => UPLOAD_PART_PROFILE.merge("partsize" => @partsize), "max_uploads" => MAX_UPLOADS, "max_parts" => MAX_PARTS,
          "state" => { "uploads" => state.uploads.size, "files" => state.files.size, "bytes_in_use" => @bytes_in_use },
        }
      end

      # Stops counting a replaced state's bytes, except versions that a download is still sending.
      def discard(state)
        state.uploads.each_value { |upload| @bytes_in_use -= upload.parts.each_value.sum { |part| part.bytes.bytesize } }
        state.files.each_value { |version| retire(version) }
      end

      # The upload number in a ref or upload URL that this simulator issued in the epoch, else nil.
      def upload_number(token, epoch)
        number_in(Token.values(token, "upload", @instance, epoch))
      end

      # The version number in a download URL that this simulator issued in the epoch, else nil.
      def version_number(token, epoch)
        number_in(Token.values(token, "download", @instance, epoch))
      end

      private

      # The simulator refuses to start rather than ignore a modeled parameter that the schema no longer
      # declares, or check one whose declared type it does not understand.
      def require_modeled_params
        missing = MODELED_PARAMS.flat_map do |operation, names|
          declared = @declared.fetch(operation)
          names.reject { |name| name == "etags" ? declared.key?("etags[etag]") && declared.key?("etags[part]") : Coercion.for(declared.fetch(name, {})) }
               .map { |name| "#{operation} parameter #{name}" }
        end
        return if missing.empty?

        raise ArgumentError, "Simulation needs #{missing.join(", ")}, which the Swagger document this server was generated from does not declare with a type the simulator checks. " \
                             "Regenerate the server from the Files.com API schema, or leave FILES_MOCK_MODE unset to use the legacy server."
      end

      def declared_names(operation)
        @declared.fetch(operation).keys.map { |name| name.sub(/\[.*/, "") }.uniq
      end

      # Returns the operation's parameters converted to their schema types, or raises before anything
      # changes: 501 for a declared parameter the simulator does not model, 422 for an invalid value or
      # for a path parameter that disagrees with the path in the URL.
      def accepted(operation, path, params)
        check_path(path)
        supplied = params.slice(*declared_names(operation)).compact
        unmodeled = supplied.keys - MODELED_PARAMS.fetch(operation)
        raise Error.not_supported("Simulation does not support these parameters: #{unmodeled.join(", ")}") if unmodeled.any?

        values = supplied.to_h { |name, value| [ name, convert(operation, name, value) ] }
        invalid = values.select { |name, value| value.equal?(Coercion::INVALID) || (name == "size" && value.negative?) }.keys
        raise Error.bad_request(invalid.map { |name| "#{name} is invalid" }.join(", ")) if invalid.any?
        raise Error.bad_request("path must match the path in the URL") if values.key?("path") && values["path"] != path

        values
      end

      def convert(operation, name, value)
        case name
        when "etags" then value # checked against the upload's parts by #listed_parts
        when "provided_mtime" then Coercion.utc_date_time(value)
        else Coercion.public_send(Coercion.for(@declared.fetch(operation).fetch(name)), value)
        end
      end

      # Checks etags [{ etag, part }] against the upload and returns the listed part numbers, 1 to N.
      # Parts are ordered by number, not by their order in the list. Every listed part must be stored
      # with the given ETag, and every stored part must be listed.
      def listed_parts(etags, upload)
        raise Error.file_not_uploaded if etags.nil? || etags == []
        raise Error.bad_request("etags is invalid") unless etags.is_a?(Array)

        listed = etags.each_with_index.map { |entry, index| listed_part(entry, index) }.sort_by(&:first)
        numbers = listed.map(&:first)
        raise Error.invalid_etags unless numbers == (1..numbers.size).to_a
        raise Error.file_not_uploaded unless listed.all? { |number, etag| upload.parts[number]&.etag == etag }

        unlisted = upload.parts.keys - numbers
        raise Error.invalid_etags("Invalid etags: uploaded part #{unlisted.sort.join(", ")} is not listed") if unlisted.any?

        numbers
      end

      # Returns [ part number, ETag without quotes ]. The number may be a decimal string, as the Go SDK sends it.
      def listed_part(entry, index)
        number = entry.is_a?(Hash) ? Coercion.int32(entry["part"]) : Coercion::INVALID
        raise Error.bad_request("etags[#{index}][part] is invalid") unless number.is_a?(Integer) && number.positive?
        raise Error.bad_request("etags[#{index}][etag] is invalid") unless entry["etag"].is_a?(String)

        [ number, entry["etag"].delete_prefix('"').delete_suffix('"') ]
      end

      def open_upload(state, ref, path)
        upload = state.uploads[upload_number(ref, state.epoch)]
        raise Error.file_upload_not_found(ref) unless upload && upload.path == path

        upload
      end

      def check_part_number(number)
        raise Error.part_number_too_large unless number.positive?
        raise Error.limit_exceeded(409, "Uploads are limited to #{MAX_PARTS} parts in the simulator") if number > MAX_PARTS
      end

      def upload_part(state, upload, number, origin)
        ref = Token.encode("upload", @instance, state.epoch, upload.id)
        UPLOAD_PART_PROFILE.merge(
          "ref" => ref, "part_number" => number, "partsize" => @partsize, "next_partsize" => @partsize,
          "upload_uri" => "#{origin}#{TRANSFER_PREFIX}/upload/#{ref}/#{number}",
          "expires" => (Time.now.utc + UPLOAD_URL_LIFETIME).strftime("%FT%TZ"), "path" => upload.path
        ).slice(*@part_fields)
      end

      def current_version(state, path)
        state.files.fetch(path) do
          raise Error.not_supported("Folders are not simulated; #{path} holds other files") if folder?(state, path)

          raise Error.not_found
        end
      end

      # The simulator accepts only paths already in the form that the Files.com API normalizes paths
      # to, because the API would silently rewrite any other form. It also refuses the names the API
      # rejects as ambiguous, rather than simulate that rejection.
      def check_path(path)
        raise Error.bad_request("The path is not valid UTF-8") unless path.valid_encoding?

        components = path.split("/", -1)
        normalized = components.none? { |component| [ "", ".", ".." ].include?(component) } && !path.match?(/[\\\0]/)
        raise Error.not_supported("#{path.inspect} is not a normalized path; send it without leading, trailing or repeated slashes, dot segments or backslashes") unless normalized

        ambiguous = components.any? { |component| @paths.ambiguous?(component) }
        raise Error.not_supported("#{path.inspect} has a name the Files.com API rejects as ambiguous, one that compares as empty, \".\" or \"..\" or contains a slash; the simulator does not simulate that rejection") if ambiguous
      end

      # Paths are exact names here, but the Files.com API compares them with its comparison map and has
      # folders. Where the API would treat a new path as another spelling of an existing file, or as
      # a folder, the simulator refuses it instead of storing a file the API would not.
      def check_namespace(state, path)
        key = @paths.key(path)
        state.files.each_key do |existing|
          next if existing == path

          other = @paths.key(existing)
          raise Error.not_supported("The Files.com API treats #{path} as the file #{existing}; the simulator does not simulate other spellings of a path") if other == key
          raise Error.not_supported("Folders are not simulated; #{path} is the folder holding #{existing}") if other.start_with?("#{key}/")
          raise Error.not_supported("Folders are not simulated; #{path} would be inside the file #{existing}") if key.start_with?("#{other}/")
        end
      end

      def folder?(state, path)
        prefix = "#{@paths.key(path)}/"
        state.files.each_key.any? { |existing| @paths.key(existing).start_with?(prefix) }
      end

      # The single byte range a Range header selects (RFC 9110, section 14) as [ first, last ], with
      # last clamped to the end of the file. Returns nil, so the whole file is sent, for no Range
      # header, one this simulator ignores (several ranges or invalid syntax), or an empty file, which
      # has no bytes to select. A range starting past the end gets 416.
      def byte_range(header, size)
        match = /\Abytes=(\d*)-(\d*)\z/i.match(header.to_s)
        return unless match && size.positive? && !(match[1].empty? && match[2].empty?)

        if match[1].empty?
          suffix = Integer(match[2], 10)
          raise Error.range_not_satisfiable(size) if suffix.zero?

          return [ [ size - suffix, 0 ].max, size - 1 ]
        end

        first = Integer(match[1], 10)
        last = Integer(match[2], 10) unless match[2].empty?
        return if last && last < first
        raise Error.range_not_satisfiable(size) if first >= size

        [ first, [ last || size, size - 1 ].min ]
      end

      def retire(version)
        version.current = false
        @bytes_in_use -= version.size if version.readers.zero?
      end

      def close_reader(version)
        version.readers -= 1
        @bytes_in_use -= version.size if version.readers.zero? && !version.current
      end

      def number_in(values)
        Integer(values.first, 10) if values&.size == 1 && values.first.match?(/\A[1-9][0-9]*\z/)
      end
    end
  end
end
