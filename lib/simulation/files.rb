module FilesMockServer
  module Simulation
    # Files, folders and file bytes, held in simulator memory (see Namespace for paths and folders). A
    # known-size upload begins with files.begin_upload, sends each part's bytes to the upload URL it
    # returns, and becomes the file's new version when files.finalize_upload has checked its parts.
    # files.download returns a URL for that version, which sends the whole file or a single byte range.
    #
    # Refs and URLs belong to one simulator instance, reset epoch, and upload or file version. Paths are
    # names in an in-memory namespace, never paths on the host. All file content held in memory is
    # counted against FILES_MOCK_MAX_TRANSFER_BYTES: stored parts, current versions, part bodies still
    # being read, and replaced or deleted versions that a download is still sending. That count spans
    # resets, because such a download may outlive the state it started in.
    #
    # Methods run under the App's lock. A download body takes the same lock when Rack closes it.
    class Files
      # Parameters each operation models. Any other parameter the schema declares for the operation is
      # refused as not simulated. A declared name such as "etags[part]" is a member of the "etags" array.
      MODELED_PARAMS = {
        "files.begin_upload" => %w[path mkdir_parents part ref size with_direct_connection_info],
        "files.finalize_upload" => %w[path action etags mkdir_parents provided_mtime ref size with_direct_connection_info],
        "files.download" => %w[path action with_direct_connection_info],
        "files.metadata" => %w[path],
        "files.delete" => %w[path recursive],
        "folders.create" => %w[path mkdir_parents provided_mtime],
        "folders.list" => %w[path cursor per_page],
        "files.copy" => %w[path destination copy_behaviors structure overwrite],
        "files.move" => %w[path destination overwrite],
        "files.update" => %w[path custom_metadata provided_mtime priority_color],
      }.freeze
      # Parameters modeled when the schema declares them and absent from schemas that predate them:
      # begin_upload's parts, the download identity parameters (local export b8129459; not in the
      # production pin), and a folder listing's with_previews (see #list_folder).
      OPTIONAL_PARAMS = { "files.begin_upload" => %w[parts], "files.download" => %w[with_download_identity expected_download_identity],
                          "folders.list" => %w[with_previews] }.freeze
      # Modeled byte counts, which take the int64 range even where the schema documents them as int32:
      # the API reads an upload's size as a Ruby Integer, so the production schema's int32 format is
      # provenance, not a limit. Every other parameter converts at its schema's width, part numbers
      # among them, and the unmodeled restart and length are refused before any conversion.
      BYTE_COUNTS = { "files.begin_upload" => %w[size], "files.finalize_upload" => %w[size] }.freeze
      # The ZIP file actions, modeled when the schema declares them (App::ZIP_OPERATIONS) and with
      # these parameters. Creating a ZIP (files.zip) follows the Rails file actions controller and
      # ZipDownload model and files-protocol-server's ZIP stream (see #zip and #create_zip).
      ZIP_PARAMS = { "files.zip_list" => %w[path], "files.unzip" => %w[path destination filename overwrite], "files.zip" => %w[paths destination overwrite] }.freeze
      # How files-protocol-server's ZIP stream numbers a repeated entry name (Utils.incrementFilename):
      # "name (N).ext" when the name has an extension, "name (N)" when it has no dot at all; any other
      # name it cannot number.
      NUMBERED_EXTENSION = /(.+?)(\.[^.\\:*?"<>|\r\n]+)\z/
      # A download identity token as Files.com issues them: fdi1. and URL-safe Base64, at most 4096 bytes.
      IDENTITY_TOKEN = /\Afdi1\.[A-Za-z0-9_-]{1,4091}\z/
      # The operations the .NET SDK sends with booleans in its query string. Their boolean
      # parameters also take "True" and "False" (Coercion::DOTNET_BOOLEANS), however they arrive;
      # no other operation does.
      DOTNET_BOOLEAN_OPERATIONS = %w[files.download files.metadata files.delete folders.list].freeze
      # The folders endpoints (/api/rest/v1/folders/...), whose whole path the API's path helper
      # checks; every other route's path it checks above the last name (Namespace#request_path).
      FOLDER_ROUTES = %w[folders.create folders.list].freeze
      # How files.finalize_upload may name the upload's parts: listed in etags, or, for a sequential
      # upload of known size, omitted so that the parts the upload received are used.
      FINALIZE_ETAGS = %w[listed omitted].freeze
      # Advertised size of each upload part, lowered to FILES_MOCK_MAX_BODY_BYTES when that is smaller.
      # Clients may send parts of any size; only the body limit bounds them.
      PARTSIZE = 5 * 1024 * 1024
      # Advertised to clients by the legacy upload profile: send one part at a time, in order, and send
      # a failed part again. The legacy profile does not enforce the order or one-at-a-time sending;
      # finalize joins parts by number. Serial and parallel profiles (Profile::Upload) check what they advertise.
      UPLOAD_PART_PROFILE = { "http_method" => "PUT", "parallel_parts" => false, "retry_parts" => true }.freeze
      MAX_UPLOADS = 64
      MAX_PARTS = 64
      # The custom_metadata a file or folder's model saves (MetadataDm): at most this many keys, and
      # keys and non-null values of at most these many characters (String#length).
      CUSTOM_METADATA_MAX_KEYS = 32
      CUSTOM_METADATA_MAX_KEY_LENGTH = 256
      CUSTOM_METADATA_MAX_VALUE_LENGTH = 1024
      # How far ahead an upload part's `expires` is set. The simulator does not enforce it.
      UPLOAD_URL_LIFETIME = 15 * 60

      # parts: part number => Part. declared_size: the size begin_upload was given, or nil. offsets: part
      # number => the part_offset its first admitted send named. sends: part number => sends admitted.
      # in_flight: part number => part bodies being read now. lengths: part number => the length the
      # part was first sent with, bound when it is known (see #admit and #bind_length). plan: part
      # number => the partsize begin_upload issued the part with.
      Upload = Struct.new(:id, :path, :parts, :declared_size, :offsets, :sends, :in_flight, :lengths, :plan) do
        def self.start(id, path, size) = new(id, path, {}, size, {}, Hash.new(0), Hash.new(0), {}, {})
      end
      # A copy or move checked against the current state: each file or folder and where it goes,
      # which folders merge into existing ones, which files it replaces, and the parents it creates.
      Relocation = Data.define(:operation, :entries, :merged, :replaced, :parents)
      # A copy or move answered as pending, applied when its FileMigration is polled to completion.
      Migration = Struct.new(:id, :operation, :path, :dest_path, :params, :status, :failure_message, :files)
      Part = Data.define(:bytes, :etag, :offset)
      # A part body, counted against the transfer byte limit, and against its upload's parts in
      # flight, from before it is read until it is stored or released.
      Received = Struct.new(:reserved, :bytes, :sha256, :stored, :upload, :part, :offset)
      # The request behind an X-Files-Download-Request-Id (Profile::Download#request_status): the
      # download URL token it was issued for, and the bytes of the stored version its response was
      # made from (nil for a failed response, which read none).
      DownloadRequest = Data.define(:number, :download_token, :bytes)
      # What the historical producer answers for a request ID or download URL it does not hold
      # (FileDownload::Stream#request_status, Errors::Download::DownloadRequestNotFound).
      DOWNLOAD_REQUEST_NOT_FOUND = "Download request expired or not found. Please try this transfer again.".freeze
      # The error a failed or error status holds. The producer stored the error that ended the
      # stream; these messages are the simulator's, under the producer's fallback type.
      DOWNLOAD_REQUEST_ERRORS = {
        "failed" => "The simulator reports this download as failed, because the reset's request_status profile chose that status.",
        "error" => "The simulator reports this download as ended by an error, because the reset's request_status profile chose that status.",
      }.freeze

      # One finalized version of a file. Its parts are frozen strings that downloads share. It stays
      # counted against the transfer byte limit while it is current or a download is sending it.
      class Version
        attr_reader :number, :parts, :size, :sha256, :mtime
        # A move gives a version its new path, and files.update a new provided_mtime; its bytes and
        # number stay the same.
        attr_accessor :path, :provided_mtime, :current, :readers

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

      attr_reader :partsize, :bytes_in_use, :namespace

      def initialize(schema, limits:, instance:, lock:)
        operations = schema.fetch("operations")
        @declared = MODELED_PARAMS.to_h { |operation, _| [ operation, operations.fetch(operation).fetch("params") ] }
        @zip_operations = ZIP_PARAMS.keys.select { |operation| operations.key?(operation) }
        @zip_operations.each { |operation| @declared[operation] = operations.fetch(operation).fetch("params") }
        require_modeled_params
        @zip_entry_fields = schema.fetch("entities").fetch("zip_list_entries", %w[path size])
        @file_fields = schema.fetch("entities").fetch("files")
        @part_fields = schema.fetch("entities").fetch("file_upload_parts")
        @migration_fields = schema.fetch("entities").fetch("file_migrations")
        @namespace = Namespace.new(max_records: limits.max_records, instance:)
        @partsize = [ PARTSIZE, limits.max_body_bytes ].min
        @max_body_bytes = limits.max_body_bytes
        @max_records = limits.max_records
        @max_bytes = limits.max_transfer_bytes
        @bytes_in_use = 0
        @instance = instance
        @signing_key = SecureRandom.bytes(32)
        @lock = lock
      end

      # Returns [ upload, [ FileUploadPart, ... ] ]: `parts` consecutive parts, one when it is omitted.
      # Without a ref it starts a new upload whose parts begin at 1, ignoring any part number as the
      # API does, and creates the file's missing parent folders; with a ref and part it returns the
      # existing upload's parts from that number, again for parts it already issued. The whole range
      # is checked before any folder, upload or part plan changes.
      def begin_upload(state, path, params, origin)
        _, values = accepted("files.begin_upload", path, params)
        count = values.fetch("parts", 1)
        raise Error.bad_request("parts is invalid") unless count.positive?

        if values.key?("ref")
          raise Error.not_supported("begin_upload with a ref but no part is not simulated") unless values.key?("part")

          upload = open_upload(state, values["ref"], path)
          first = values["part"]
          check_part_range(first, count)
        else
          check_part_range(first = 1, count)
          parents = file_parents(state, path, publishing: false)
          refuse_missing_parents(state, parents, values)
          raise Error.limit_exceeded(409, "The simulator already holds #{MAX_UPLOADS} unfinished uploads; finalize them or reset") if state.uploads.size >= MAX_UPLOADS

          @namespace.reserve(state, parents.size)
          @namespace.add_parents(state, parents)
          upload = Upload.start(state.last_upload_id += 1, path, values["size"])
          state.uploads[upload.id] = upload
        end
        [ upload, (first...(first + count)).map { |number| upload_part(state, upload, number, origin) } ]
      end

      # Admits a part body of up to `size` bytes before it is read: counts it against the transfer
      # byte limit and, under a serial or parallel upload profile, checks it against the profile.
      # An admitted part holds a place until #release, and the state records the most parts that
      # held one at once. target: the route's values (upload number and part), or nil when the
      # state they were resolved in has since been reset. offset: the part_offset query value, or
      # nil. declared: the body's Content-Length, or nil.
      def admit(state, target, size, offset, declared:)
        upload = target && state.uploads[target["upload"]]
        number = target && target["part"]
        profile = state.profile.upload
        raise Error.not_supported("part_offset is accepted only when the upload profile advertises part_offset_query") if offset && !profile.part_offset_query

        admission(state, upload, number, declared, offset, profile) if upload && number && !profile.legacy?
        raise Error.limit_exceeded(409, "Holding #{size} more bytes would pass the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{@bytes_in_use} are in use") if @bytes_in_use + size > @max_bytes

        @bytes_in_use += size
        if upload && number
          upload.sends[number] += 1
          upload.in_flight[number] += 1
          upload.offsets[number] ||= offset
          upload.lengths[number] ||= declared if declared && !profile.legacy?
          state.observe_parts_in_flight(parts_in_flight(state))
        end
        Received.new(size, nil, nil, false, (upload if number), number, offset)
      end

      # The parts holding a place now across the uploads not yet finalized: admitted (#admit) and not
      # yet released (#release). upload.max_concurrent_parts limits this count.
      def parts_in_flight(state)
        state.uploads.each_value.sum { |upload| upload.in_flight.each_value.sum }
      end

      # Binds the length of a part body read in full when no Content-Length gave it earlier (a
      # chunked body), under a serial or parallel profile. A body the transport cut short is never
      # read in full, so its prefix binds nothing. Raises when the part was first sent with another
      # length: a part keeps its intended length through faults, retries and renewed URLs.
      def bind_length(state, received)
        upload = received.upload
        return unless upload && !state.profile.upload.legacy?

        length = received.bytes.bytesize
        intended = upload.lengths[received.part] ||= length
        raise Error.profile_violation(409, changed_length(received.part, intended, length)) unless intended == length
      end

      def release(received)
        @bytes_in_use -= received.reserved unless received.stored
        received.upload.in_flight[received.part] -= 1 if received.upload
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

        limits = state.profile.upload.variable_part_limits
        raise Error.profile_violation(422, "Part #{number} holds #{received.bytes.bytesize} bytes; the upload profile allows at most #{limits["max_part_bytes"]} per part") if limits && received.bytes.bytesize > limits["max_part_bytes"]

        @bytes_in_use -= received.reserved - received.bytes.bytesize
        received.stored = true
        upload.parts[number] = Part.new(received.bytes, received.sha256, received.offset)
      end

      # Checks the upload's parts, then makes them, in part number order, the file's new version in one
      # step, creating any parent folder deleted since the upload began. Returns [ status, upload,
      # version ]. A failure leaves the upload open and the file's current version in place.
      def finalize_upload(state, path, params)
        _, values = accepted("files.finalize_upload", path, params)
        raise Error.bad_request("action is missing") unless values.key?("action")
        raise Error.not_supported("Only action=end, which finalizes an upload, is simulated for POST /files/{path}") unless values["action"] == "end"
        raise Error.request_params_required("ref") if values["ref"].to_s.empty?
        raise Error.not_supported("etags: null is not simulated; list every part in etags, or leave etags out of a sequential upload of known size") if params.key?("etags") && params["etags"].nil?

        upload = open_upload(state, values["ref"], path)
        profile = state.profile.upload
        unsized = profile.variable_part_limits && upload.declared_size.nil? && !(values.key?("size") && values.key?("etags"))
        raise Error.profile_violation(422, "An upload begun without size needs its final size and the etags of every part to finish") if unsized

        numbers = values.key?("etags") ? listed_parts(values["etags"], upload) : received_parts(values, upload)
        check_profile_parts(profile, upload, numbers) unless profile.legacy?
        parts = numbers.map { |number| upload.parts.fetch(number).bytes }
        size = parts.sum(&:bytesize)
        raise Error.request_params_invalid("size is #{values["size"]}, but the parts hold #{size} bytes") if values.key?("size") && values["size"] != size

        parents = file_parents(state, path, publishing: true)
        refuse_missing_parents(state, parents, values)
        previous = state.files[path]
        @namespace.reserve(state, parents.size + (previous ? 0 : 1))
        @namespace.add_parents(state, parents)
        version = Version.new(path, state.commits += 1, parts.freeze, values["provided_mtime"])
        state.files[path] = version
        state.uploads.delete(upload.id)
        # A new version is a new file: what files.update set on the old one does not carry over.
        state.file_metadata.delete(path) if previous
        retire(previous) if previous
        [ previous ? 200 : 201, upload, version ]
      end

      # Returns [ file or folder, download URL or nil, download identity or nil ]. With action=stat it
      # describes the file or folder without a download URL; with no action it returns a download URL
      # for exactly the file's current version. The root is named "/". Under the contract_v1 download
      # profile, with_download_identity or expected_download_identity also returns the version's
      # identity (see #identity_for). Under a request_status profile the URL is recorded as issued
      # (#record_download_transfer).
      def download(state, path, params, origin)
        name, values = accepted("files.download", path, params, root: true)
        expected = identity_request(state, params)
        entry = @namespace.find(state, name) || raise(Error.not_found)
        raise Error.identity_parameter(expected == true ? "with_download_identity" : "expected_download_identity") if expected && (values["action"].to_s != "" || entry.is_a?(Namespace::Folder))

        case values["action"]
        when "stat" then [ entry, nil, nil ]
        when nil, ""
          raise Error.cannot_download_directory if entry.is_a?(Namespace::Folder)

          identity = identity_for(state, entry, expected) if expected
          token = Token.encode(expected ? "download-identity" : "download", @instance, state.epoch, entry.number)
          record_download_transfer(state, token)
          [ entry, transfer_url(state, "GET", origin, "download/#{token}"), identity ]
        else raise Error.not_supported("GET /files/{path} is simulated with action=stat or without an action; action=#{values["action"]} is not")
        end
      end

      def metadata(state, path, params, accept_language: nil)
        name, = accepted("files.metadata", path, params, root: true)
        @namespace.find(state, name) || raise(Error.not_found_for(accept_language))
      end

      # Deletes the file, or the folder, at path and returns [ it, what was removed inside it ]. A
      # folder holding files or folders is refused unless recursive is true, which removes everything
      # strictly inside it ("a/b", never "ab") and then the folder. The root is never deleted.
      def delete(state, path, params)
        name, values = accepted("files.delete", path, params, root: true)
        entry = @namespace.find(state, name) || raise(Error.not_found)
        return [ entry, {} ].tap { remove_file(state, entry) } unless entry.is_a?(Namespace::Folder)
        return [ entry, {} ].tap { @namespace.remove_folder(state, entry) && state.file_metadata.delete(name) } unless values["recursive"]
        raise Error.not_supported("Deleting the root recursively is not simulated") if name == Namespace::ROOT

        folders, files = @namespace.subtree(state, name)
        files.each { |version| remove_file(state, version) }
        (folders.reverse << entry).each do |folder|
          state.folders.delete(folder.path)
          state.file_metadata.delete(folder.path)
        end
        [ entry, { "files" => files.size, "folders" => folders.size } ]
      end

      # Copies the file, or the folder with everything inside it, to destination; structure copies a
      # folder's folders only. Returns [ FileAction, journal fields ]; see #file_action.
      def copy(state, path, params, profile)
        source, values = accepted("files.copy", path, params)
        raise Error.not_supported("copy_behaviors is not simulated: behaviors, notification subscriptions and branding are not modeled") if values["copy_behaviors"]

        file_action(state, "copy", source, values, profile)
      end

      # Moves (renames) the file, or the folder with everything inside it, to destination.
      def move(state, path, params, profile)
        source, values = accepted("files.move", path, params)
        file_action(state, "move", source, values, profile)
      end

      # The FileMigration a pending copy or move reported. It is "processing" when first polled and,
      # when polled again, is checked against the state at that moment and applied in one step
      # ("completed") or refused without any change ("failed", with the reason). Returns
      # [ FileMigration, journal fields ].
      def migration(state, id)
        migration = state.migrations[id] || raise(Error.not_found)
        fields = {}
        case migration.status
        when "pending" then migration.status = "processing"
        when "processing"
          begin
            fields = case migration.operation
                     when "unzip" then extract(state, migration)
                     when "zip" then create_zip(state, migration)
                     else apply(state, relocation(state, migration.operation, migration.path, migration.dest_path, migration.params))
                     end
            migration.files = fields["files"]
            migration.status = "completed"
          rescue Error => e
            migration.status = "failed"
            migration.failure_message = e.message
            fields = { "failed" => e.type }
          end
        end
        [ present_migration(migration), fields.merge("migration_status" => migration.status) ]
      end

      # The entries of the ZIP file at path, as zip_list answers them: each one's path and
      # uncompressed size, in the order of the archive's central directory, folders ("dir/") included.
      def zip_list(state, path, params)
        name, = accepted("files.zip_list", path, params)
        entry = @namespace.find(state, name) || raise(Error.not_found)
        raise Error.folders_not_allowed if entry.is_a?(Namespace::Folder)

        archive(entry).entries.map { |item| { "path" => item.path, "size" => item.size }.slice(*@zip_entry_fields) }
      end

      # Starts extracting the ZIP file `path` into the folder `destination`, as Files.com does: the
      # file must exist and not be a folder, and the destination folder and its parents are created
      # now. The extraction itself is a FileMigration, always answered pending ({"status" =>
      # "pending", "file_migration_id"}) whatever the file_actions profile, and applied when it is
      # polled to completion (#migration, #extract). Returns [ FileAction, journal fields ].
      #
      # A `path` or `destination` sent null or empty passes the API's parameter validation and names the
      # site root, as its path and destination helpers normalize it: a root `path` is a folder, refused
      # as any folder is, and a root `destination` is the root folder, which the extraction fills.
      def unzip(state, params)
        raise Error.bad_request("path is missing") unless params.key?("path")

        source, values = accepted("files.unzip", params["path"].to_s, params)
        zip = @namespace.find(state, source) || raise(Error.not_found)
        raise Error.folders_not_allowed if zip.is_a?(Namespace::Folder)

        destination = @namespace.request_path(values["destination"].to_s)
        refuse_trailing_whitespace(destination)
        existing = @namespace.find(state, destination)
        raise Error.folder_must_not_be_a_file if existing && !existing.is_a?(Namespace::Folder)
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} file migrations (FILES_MOCK_MAX_RECORDS); reset to release them") if state.migrations.size >= @max_records

        unless existing
          created = @namespace.missing_parents(state, destination) << destination
          @namespace.reserve(state, created.size)
          @namespace.add_parents(state, created)
        end
        id = state.last_migration_id += 1
        state.migrations[id] = Migration.new(id, "unzip", source, destination, values, "pending", nil, nil)
        [ { "status" => "pending", "file_migration_id" => id }, { "migration" => id, "destination_created" => existing.nil? } ]
      end

      # Starts saving a ZIP of `paths` as the file `destination`, in the Rails file actions
      # controller's order: `paths` is required and deduplicated in request order, and each path must
      # exist; then the destination is checked (Namespace's spelling rules and the API's
      # trailing-whitespace rule for its folders) and its missing parent folders are created; then
      # ZipDownload's validation requires the selection to hold at least one file (an empty file
      # counts, a folder whose tree holds none does not). A selection refused by that validation
      # keeps the parents already created, and no migration is made. The ZIP itself is a
      # FileMigration, always answered pending whatever the file_actions profile, and made when it is
      # polled to completion (#migration, #create_zip), so an existing destination is decided then,
      # not now. Its path is the first requested path. Returns [ FileAction, journal fields ].
      #
      # Paths are compared exactly as sent: the simulator accepts only the normalized spelling
      # (Namespace), so an exact duplicate is the only one it can see. It checks no permissions (see
      # App::REAL_ONLY), and its no-files refusal has Files.com's error type and status but not its
      # validation message, which the simulator does not model. The simulator's own limits (records
      # and retained migrations) are checked before anything is created.
      #
      # `paths` sent null or empty ("" is an empty array to the API's coercion) is the controller's
      # blank-selection refusal. A `destination` sent null or empty is the site root: the API checks the
      # selection and ZipDownload as usual, then the FileMigration it creates fails its dest_path
      # presence validation, which it answers with its catch-all 500; no migration is made.
      def zip(state, params)
        _, values = accepted("files.zip", nil, params)
        raise Error.request_params_required("paths") if values["paths"].nil? || values["paths"].empty?

        requested = values["paths"].uniq.map { |path| @namespace.request_path(path) }
        records = requested.map { |path| @namespace.find(state, path) || raise(Error.not_found) }
        destination = @namespace.request_path(values["destination"].to_s)
        refuse_trailing_whitespace(destination)
        parents = @namespace.missing_parents(state, destination)
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} file migrations (FILES_MOCK_MAX_RECORDS); reset to release them") if state.migrations.size >= @max_records

        @namespace.reserve(state, parents.size)
        @namespace.add_parents(state, parents)
        file_less = records.none? { |record| record.is_a?(Version) || @namespace.subtree(state, record.path).last.any? }
        raise Error.new(422, "processing-failure/model-save-error", "Model Save Error", "The ZIP would hold no files: every selected folder is empty (the simulator does not model Files.com's validation message)") if file_less
        raise Error.server_error if destination == Namespace::ROOT

        id = state.last_migration_id += 1
        state.migrations[id] = Migration.new(id, "zip", requested.first, destination, values.merge("paths" => requested), "pending", nil, nil)
        [ { "status" => "pending", "file_migration_id" => id }, { "migration" => id, "selected" => requested.size, "parents_created" => parents.size } ]
      end

      # Folders and files a reset starts with: "folders" is a list of paths, "files" a list of
      # { "path", "text" or "base64", "provided_mtime" }. Checked completely before anything is kept.
      # Their bytes are limited together with what stays counted once `replacing` is discarded.
      def load_fixtures(state, folders, files, replacing:)
        raise Error.invalid_control("fixtures.folders must be an array of paths") unless folders.is_a?(Array) && folders.all?(String)
        raise Error.invalid_control("fixtures.files must be an array of JSON objects") unless files.is_a?(Array) && files.all?(Hash)

        raise Error.invalid_control("fixtures.folders must not name the root") if folders.include?("") || folders.include?(Namespace::ROOT_SPELLING)

        folders.each_with_index { |path, index| fixture_error("folders[#{index}]") { @namespace.create_folder(state, @namespace.request_path(path), nil) } }
        # The new state is not in use yet, so its files are kept as they are checked and counted
        # against the transfer byte limit only when all of them are.
        versions = files.each_with_index.map do |spec, index|
          path, bytes, provided_mtime = fixture_error("files[#{index}]") { fixture_file(state, spec) }
          state.files[path] = Version.new(path, state.commits += 1, [ bytes.freeze ].freeze, provided_mtime)
        end
        size = versions.sum(&:size)
        staying = @bytes_in_use - discarded_bytes(replacing)
        raise Error.limit_exceeded(409, "The file fixtures hold #{size} bytes; with #{staying} still in use that passes the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES)") if staying + size > @max_bytes

        @bytes_in_use += size
        { "folders" => folders.size, "files" => files.size }
      end

      # Creates exactly this folder, and any missing parents, and returns it.
      def create_folder(state, path, params)
        name, values = accepted("folders.create", path, params, root: true)
        refuse_missing_parents(state, @namespace.missing_parents(state, name), values) unless name == Namespace::ROOT
        @namespace.create_folder(state, name, values["provided_mtime"])
      end

      # Returns [ one page of the folder's files and folders, next cursor or nil ]; see Namespace#list.
      # with_previews asks for each file's preview, which is not simulated, so a page that would hold a
      # file is refused; folders have no previews, so a page of folders is the same either way.
      def list_folder(state, path, params)
        name, values = accepted("folders.list", path, params, root: true)
        folder = @namespace.find(state, name) || raise(Error.not_found)
        raise Error.not_supported("Listing a file's path is not simulated; list its folder") unless folder.is_a?(Namespace::Folder)

        @namespace.list(state, folder.path, values["per_page"], values["cursor"], folders_only: values["with_previews"] == true)
      end

      # Changes a file's or folder's provided_mtime, custom_metadata or priority_color (PATCH
      # /files/{path}) and returns it. The metadata stays with the path through moves and copies and
      # ends with the file or folder, or when a finalize replaces the file. custom_metadata replaces the
      # whole object; a null one clears it, as the model stores nil and reads back its default, {}. An
      # update the model would not save (#refuse_unsaved_metadata) changes none of them.
      def update_file(state, path, params)
        name, values = accepted("files.update", path, params)
        entry = @namespace.find(state, name) || raise(Error.not_found)
        changes = values.slice("custom_metadata", "priority_color")
        changes["custom_metadata"] = {} if params.key?("custom_metadata") && params["custom_metadata"].nil?
        refuse_unsaved_metadata(changes["custom_metadata"])
        if values.key?("provided_mtime")
          if entry.is_a?(Namespace::Folder)
            entry = state.folders[name] = entry.with(provided_mtime: values["provided_mtime"])
          else
            entry.provided_mtime = values["provided_mtime"]
          end
        end
        state.file_metadata[name] = state.file_metadata.fetch(name, {}).merge(changes) if changes.any?
        entry
      end

      # A file's or folder's File object, with a file's download URL when it has one and what
      # files.update set on it (given `state`). Fields the simulator does not model, such as creators,
      # permissions and locks, are left out.
      def present(entry, download_uri = nil, state: nil)
        fields = if entry.is_a?(Namespace::Folder)
                   { "path" => entry.path, "display_name" => entry.path.split("/").last.to_s, "type" => "directory",
                     "mtime" => entry.mtime, "provided_mtime" => entry.provided_mtime }
                 else
                   { "path" => entry.path, "display_name" => entry.path.split("/").last, "type" => "file", "size" => entry.size,
                     "mtime" => entry.mtime, "provided_mtime" => entry.provided_mtime, "download_uri" => download_uri }
                 end
        fields.compact.merge(state&.file_metadata&.fetch(entry.path, nil).to_h).slice(*@file_fields)
      end

      # The current version with the given number, or nil.
      def version_by_number(state, number)
        state.files.each_value.find { |version| version.number == number }
      end

      # Returns [ version, Rack response ] sending the version a download URL names: the whole file, or
      # one byte range. The URL of a replaced version is refused, but a response already sending it
      # finishes from the same bytes, which stay counted until Rack closes the body. Under a withheld
      # download size the whole file is sent without Content-Length and a range's total is "*".
      def send_version(state, target, range_header, if_match)
        number = target["version"]
        version = version_by_number(state, number)
        changed_status = target["identity"] ? 412 : 409
        raise Error.download_source_changed(changed_status) if version.nil? && number && number <= state.commits
        raise Error.not_found unless version

        if target["identity"]
          raise Error.profile_violation(400, "This download URL requires the If-Match header its download identity lists") if if_match.nil?
          raise Error.download_source_changed(412) unless if_match == %("#{version.sha256}")
        end

        range = byte_range(range_header, version.size)
        first, last = range || [ 0, version.size - 1 ]
        headers = { "content-type" => "application/octet-stream", "content-length" => (last - first + 1).to_s, "accept-ranges" => "bytes", "etag" => %("#{version.sha256}") }
        withheld = state.profile.download.size_withheld?
        headers.delete("content-length") if withheld && !range
        headers["content-range"] = "bytes #{first}-#{last}/#{withheld ? "*" : version.size}" if range
        version.readers += 1
        [ version, [ range ? 206 : 200, headers, Download.new(version, first, last) { @lock.synchronize { close_reader(version) } } ] ]
      end

      # Returns [ response, journal fields ]: a storage download response with the request ID and
      # download ID headers the historical producer set when a GET began streaming, recording the
      # bytes the response was made from, or the response unchanged when the reset's profile has no
      # request_status. A reset keeps the newest FILES_MOCK_MAX_RECORDS requests; an older one's ID
      # is then answered as the producer answers an expired one.
      def issue_download_request(state, target, response, bytes)
        return [ response, {} ] unless state.profile.download.request_status?

        number = state.last_download_request_id += 1
        state.download_requests.shift if state.download_requests.size >= @max_records
        state.download_requests[number] = DownloadRequest.new(number:, download_token: target["download_token"], bytes:)
        status, headers, body = response
        headers = headers.merge("x-files-download-request-id" => download_request_id(state, number), "x-files-download-id" => target["download_token"])
        [ [ status, headers, body ], { "download_request" => number } ]
      end

      # Records a download URL files.download issued, as the producer stored the transfer a download
      # URL named, so a status lookup answers only at a transfer that exists: one whose version was
      # never made, or whose URL was never issued, is not one. The URL stays issued when its file is
      # replaced. A reset keeps the newest FILES_MOCK_MAX_RECORDS; nothing is kept without a
      # request_status profile.
      def record_download_transfer(state, token)
        return unless state.profile.download.request_status?

        state.download_transfers.delete(token)
        state.download_transfers.shift if state.download_transfers.size >= @max_records
        state.download_transfers[token] = true
      end

      # The historical producer's status lookup at a download URL joined with a request ID: the
      # request first, then the transfer the URL names, which must be a download URL files.download
      # issued in this reset and that is still held (#record_download_transfer); 404
      # download_request_not_found for either one missing, else 200 with the status the reset
      # chose, and the error it holds for failed and error. The URL's query is not checked, as the
      # producer skipped its expiry check here. Returns [ Rack response, journal fields ].
      def download_request_status(state, target)
        request, lookup = find_download_request(state, target["request_id"])
        data = { "file_download_id" => target["download_token"], "request_id" => request && download_request_id(state, request.number) }
        data.update(download_request_data(state, request)) if request
        found = request && state.download_transfers.key?(target["download_token"])
        lookup = "no_transfer" if request && !found
        lookup = "found_for_other_url" if found && request.download_token != target["download_token"]
        http_code, type, error = if !found then [ 404, "download_request_not_found", DOWNLOAD_REQUEST_NOT_FOUND ]
                                 elsif DOWNLOAD_REQUEST_ERRORS.key?(data["status"]) then [ 200, "download_error", DOWNLOAD_REQUEST_ERRORS.fetch(data["status"]) ]
                                 else
                                   [ 200, nil, nil ]
                                 end
        body = { "type" => type, "title" => nil, "error" => error, "http_code" => http_code, "errors" => nil, "data" => data }
        [ [ http_code, { "content-type" => "application/json" }, [ JSON.generate(body) ] ], { "download_request" => request&.number, "download_request_lookup" => lookup }.compact ]
      end

      def readiness(state)
        {
          "upload_parts" => advertised(state.profile.upload), "max_uploads" => MAX_UPLOADS, "max_parts" => MAX_PARTS,
          "finalize_etags" => FINALIZE_ETAGS,
          "file_actions" => { "operations" => %w[files.copy files.move], "overwrite" => "files replace files and folders merge into folders", "structure" => true, "copy_behaviors" => false,
                              "migration_statuses" => %w[pending processing completed failed] },
          "zip" => (if @zip_operations.any?
                      { "operations" => @zip_operations, "zip_creation" => @zip_operations.include?("files.zip"), "methods" => %w[stored deflate], "entry_names" => %w[utf-8-flagged ascii], "zip64" => false,
                        "crc_checked" => false, "unzip_migration" => "pending, applied when polled; the whole extraction is checked before any change",
                        "zip_migration" => ("pending, made when polled from the files at that moment; the destination is checked then" if @zip_operations.include?("files.zip")) }.compact
                    end),
          "download_request_status" => { "operation" => DOWNLOAD_STATUS_OPERATION.slice("id", "method").merge("path" => "#{TRANSFER_PREFIX}#{DOWNLOAD_STATUS_OPERATION["path"]}"),
                                         "headers" => [ "X-Files-Download-Request-Id", "X-Files-Download-Id" ], "selected" => state.profile.download.request_status,
                                         "size" => state.profile.download.size, "issued" => state.last_download_request_id, "held" => state.download_requests.size,
                                         "transfers_held" => state.download_transfers.size, "max_held" => @max_records },
          "state" => { "uploads" => state.uploads.size, "files" => state.files.size, "bytes_in_use" => @bytes_in_use },
        }.compact
      end

      # The bytes #discard stops counting.
      def discarded_bytes(state)
        state.uploads.each_value.sum { |upload| upload.parts.each_value.sum { |part| part.bytes.bytesize } } +
          state.files.each_value.sum { |version| version.readers.zero? ? version.size : 0 }
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

      # The route values of a download URL: the version number it names, when this simulator issued
      # it in the epoch (else nil), and whether it was issued with a download identity.
      def download_target(token, epoch)
        identity = number_in(Token.values(token, "download-identity", @instance, epoch))
        return { "version" => identity, "identity" => true } if identity

        { "version" => number_in(Token.values(token, "download", @instance, epoch)) }
      end

      # Under the signed_urls profile, refuses a transfer whose URL query is not exactly the presigned
      # query this simulator issued for its method and path (see #transfer_url).
      def check_signature(state, method, path, query)
        return unless state.profile.signed_urls?

        unsigned, signature = query.to_s.split("&X-Amz-Signature=", 2)
        raise Error.storage(403, "AccessDenied", "Query-string authentication requires the Signature, Expires and AWSAccessKeyId parameters") unless signature

        raise Error.storage(403, "SignatureDoesNotMatch", "The request signature we calculated does not match the signature you provided.") unless signature == signature_of(method, path, unsigned)
      end

      # The reset's Profile for a reset body's "profile", checked against this server's schema and limits.
      def profile(spec)
        Profile.new(spec, part_fields: @part_fields, default_partsize: @partsize, max_body_bytes: @max_body_bytes)
      end

      private

      # A transfer URL; under the signed_urls profile, with a synthetic presigned query whose credential
      # is a sentinel and whose signature covers the method, path and exact query bytes.
      def transfer_url(state, method, origin, route)
        path = "#{TRANSFER_PREFIX}/#{route}"
        return "#{origin}#{path}" unless state.profile.signed_urls?

        now = Time.now.utc
        credential = ERB::Util.url_encode("SIMULATEDSENTINELKEY/#{now.strftime("%Y%m%d")}/us-east-1/s3/aws4_request")
        query = "X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=#{credential}&X-Amz-Date=#{now.strftime("%Y%m%dT%H%M%SZ")}" \
                "&X-Amz-Expires=#{state.profile.url_lifetime}&X-Amz-SignedHeaders=host"
        "#{origin}#{path}?#{query}&X-Amz-Signature=#{signature_of(method, path, query)}"
      end

      def signature_of(method, path, query)
        OpenSSL::HMAC.hexdigest("SHA256", @signing_key, "#{method}\n#{path}\n#{query}")
      end

      # What begin_upload advertises under an upload profile.
      def advertised(profile)
        return UPLOAD_PART_PROFILE.merge("partsize" => @partsize) if profile.legacy?

        { "http_method" => "PUT", "parallel_parts" => profile.parallel?, "retry_parts" => profile.retry_parts, "partsize" => profile.partsize,
          "variable_part_limits" => profile.variable_part_limits, "part_offset_query" => (true if profile.part_offset_query),
          "upload_target_class" => profile.upload_target_class }.compact
      end

      # Checks a part send against a serial or parallel upload profile before its body is read.
      def admission(state, upload, number, declared, offset, profile)
        check_part_number(number)
        in_flight = parts_in_flight(state)
        if profile.max_concurrent_parts && in_flight >= profile.max_concurrent_parts
          throttled = "#{in_flight} parts are being sent; the upload profile admits at most #{profile.max_concurrent_parts} at once"
          raise Error.profile_violation(503, throttled, headers: { "retry-after" => profile.throttle_retry_after.to_s })
        end
        unless profile.parallel?
          sending = upload.in_flight.select { |_, count| count.positive? }.keys
          raise Error.profile_violation(409, "Part #{sending.join(", ")} of this upload is still being sent; the serial upload profile admits one part at a time") if sending.any?

          missing = (1...number).reject { |earlier| upload.parts.key?(earlier) }
          raise Error.profile_violation(409, "Part #{number} was sent before part #{missing.join(", ")}; the serial upload profile admits parts in order") if missing.any?
        end
        raise Error.profile_violation(409, "Part #{number} was already sent; the upload profile does not allow retrying parts, so restart the upload") if !profile.retry_parts && upload.sends[number].positive?

        scheduled = upload.offsets[number]
        raise Error.profile_violation(409, "Part #{number} was first sent with part_offset #{scheduled.inspect}; every send of a part must name the same offset") if upload.sends[number].positive? && scheduled != offset

        intended = upload.lengths[number]
        raise Error.profile_violation(409, changed_length(number, intended, declared)) if intended && declared && intended != declared

        limits = profile.variable_part_limits
        raise Error.profile_violation(422, "Part #{number} declares #{declared} bytes; the upload profile allows at most #{limits["max_part_bytes"]} per part") if limits && declared && declared > limits["max_part_bytes"]
      end

      def changed_length(number, intended, length)
        "Part #{number} was first sent with #{intended} bytes and is now sent with #{length}; every send of a part must carry the same bytes"
      end

      # The partsize a part is issued with: the upload's binding when begin_upload already issued it,
      # else the profile's (partsize, changed for later parts by partsize_changes).
      def planned_partsize(upload, profile, number)
        upload.plan[number] || profile.partsize_for(number)
      end

      # Checks the parts a finalize joins, in part number order, against the upload profile: their
      # sizes against variable_part_limits when the profile sets them, and their offsets when any part
      # named one. The partsize a part was issued with is a hint, as next_partsize is: a part of
      # another size is not refused for it, and its body is bounded like any other
      # (FILES_MOCK_MAX_BODY_BYTES, FILES_MOCK_MAX_TRANSFER_BYTES).
      def check_profile_parts(profile, upload, numbers)
        parts = numbers.map { |number| upload.parts.fetch(number) }
        sizes = parts.map { |part| part.bytes.bytesize }
        if (limits = profile.variable_part_limits)
          raise Error.profile_violation(422, "The upload has #{parts.size} parts; the upload profile allows at most #{limits["max_parts"]}") if parts.size > limits["max_parts"]
          raise Error.profile_violation(422, "The parts hold #{sizes.sum} bytes; the upload profile allows at most #{limits["max_file_bytes"]} per file") if sizes.sum > limits["max_file_bytes"]

          short = sizes[0...-1].each_index.select { |index| sizes[index] < limits["min_nonfinal_bytes"] }.map(&:succ)
          raise Error.profile_violation(422, "Part #{short.join(", ")} holds fewer than min_nonfinal_bytes (#{limits["min_nonfinal_bytes"]}) and is not the last part") if short.any?
        end
        offsets = parts.map(&:offset)
        return if offsets.all?(&:nil?)
        raise Error.profile_violation(422, "Some parts were sent with part_offset and some without; send it with every part") if offsets.any?(&:nil?)

        expected = sizes.each_with_index.map { |_, index| sizes.first(index).sum }
        wrong = offsets.each_index.reject { |index| offsets[index] == expected[index] }
        raise Error.profile_violation(422, "Part #{wrong.first + 1} was sent with part_offset #{offsets[wrong.first]}, but the parts before it hold #{expected[wrong.first]} bytes") if wrong.any?
      end

      # True when the request asks for a download identity, the expected identity token when it names
      # one, else nil. with_download_identity takes "True" and "False" too, as files.download's other
      # boolean parameters do (DOTNET_BOOLEAN_OPERATIONS), which is how the Python SDK sends it in a
      # query string. A malformed token, or with_download_identity=false beside a token, is refused
      # with 400 as Files.com refuses it. Under the "absent" profile the site's download identity
      # setting is off: with_download_identity gets an ordinary download, and a declared
      # expected_download_identity gets 422 download-identity-unavailable (fail closed). Where the
      # schema does not declare the parameters (the production pin), "absent" ignores them as a server
      # without them does, and "contract_v1" simulates them ahead of that schema.
      def identity_request(state, params)
        declared = @declared.fetch("files.download").key?("expected_download_identity")
        return if state.profile.download.identity == "absent" && !declared

        expected = params["expected_download_identity"]
        raise Error.identity_parameter("expected_download_identity") unless expected.nil? || (expected.is_a?(String) && expected.match?(IDENTITY_TOKEN))

        requested = params.key?("with_download_identity") ? Coercion.dotnet_boolean(params["with_download_identity"]) : nil
        raise Error.identity_parameter("with_download_identity") if requested.equal?(Coercion::INVALID) || (expected && requested == false)
        raise Error.download_identity_unavailable if expected && state.profile.download.identity == "absent"
        return if state.profile.download.identity == "absent"

        expected || (true if requested)
      end

      # The download identity of a file's current version: { version: 1, token, size,
      # required_headers }. The token names the file and version, so renewing with it returns the
      # same token while the version is current, and 422 download-identity-unavailable once it has
      # been replaced, even by a file of the same size. A well-formed token this simulator cannot
      # authenticate (another process, reset epoch or file) is unavailable too.
      def identity_for(state, version, expected)
        scope = Digest::SHA256.hexdigest(version.path)[0, 16]
        if expected.is_a?(String)
          encoded = expected.delete_prefix("fdi1.").tr("-_", "+/")
          fields = begin
            (encoded + ("=" * (-encoded.size % 4))).unpack1("m0").force_encoding(Encoding::UTF_8).split(":", -1)
          rescue ArgumentError
            []
          end
          number = number_in(fields.drop(4)) if fields.first(4) == [ "identity", @instance, state.epoch.to_s, scope ] && fields.size == 5
          raise Error.download_identity_unavailable unless number == version.number
        end
        token = "fdi1.#{[ [ "identity", @instance, state.epoch, scope, version.number ].join(":") ].pack("m0").tr("+/", "-_").delete("=")}"
        { "version" => 1, "token" => token, "size" => version.size, "required_headers" => { "If-Match" => %("#{version.sha256}") } }
      end

      def remove_file(state, version)
        state.files.delete(version.path)
        state.file_metadata.delete(version.path)
        retire(version)
      end

      # A copy or move applied now or, with the pending profile, recorded as a FileMigration. Overwriting
      # the site root (#relocation returns no plan) is always enqueued by the API, and the FileMigration it
      # creates fails its dest_path presence validation: the catch-all 500, where the migration would be
      # made, and nothing changes.
      def file_action(state, operation, source, values, profile)
        plan = relocation(state, operation, source, values["destination"], values)
        pending = profile.file_actions == "pending"
        return [ { "status" => "completed" }, apply(state, plan) ] if plan && !pending

        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} file migrations (FILES_MOCK_MAX_RECORDS); reset to release them") if pending && state.migrations.size >= @max_records
        raise Error.server_error unless plan

        id = state.last_migration_id += 1
        migration = state.migrations[id] = Migration.new(id, operation, source, values["destination"], values, "pending", nil, nil)
        [ { "status" => "pending", "file_migration_id" => migration.id }, { "migration" => migration.id } ]
      end

      # Checks a copy or move against the state and returns its Relocation, or raises before anything
      # changes. The destination must not exist unless overwrite is true, in which case files replace
      # files and folders merge into folders; any other combination is not simulated. A destination sent
      # null or empty is the site root, as the API's destination helper normalizes it: it exists, so
      # without overwrite it is refused as existing, and with overwrite there is no plan (#file_action).
      def relocation(state, operation, source, destination, values)
        destination = @namespace.request_path(destination.to_s)
        entry = @namespace.find(state, source) || raise(Error.not_found)
        refuse_trailing_whitespace(destination)
        if destination == Namespace::ROOT
          raise Error.destination_exists("The destination exists.") unless values["overwrite"]

          return
        end
        raise Error.not_supported("Copying or moving #{source} into itself is not simulated") if @namespace.within?(destination, source)
        raise Error.not_supported("Copying or moving #{source} onto a folder that holds it is not simulated") if @namespace.within?(source, destination)
        raise Error.not_supported("structure copies a folder's folders; it is not simulated for a file") if values["structure"] && !entry.is_a?(Namespace::Folder)

        entries = [ [ entry, destination ] ]
        if entry.is_a?(Namespace::Folder)
          folders, files = @namespace.subtree(state, source)
          files = [] if values["structure"]
          entries += (folders + files).map { |record| [ record, destination + record.path.delete_prefix(source) ] }
        end
        merged, replaced = [], []
        entries.each do |record, target|
          existing = @namespace.find(state, target) or next
          raise Error.destination_exists("The destination exists.") unless values["overwrite"]
          raise Error.not_supported("Overwriting a #{kind(existing)} with a #{kind(record)} is not simulated") unless kind(existing) == kind(record)

          (existing.is_a?(Namespace::Folder) ? merged : replaced) << target
        end
        parents = @namespace.missing_parents(state, destination)
        raise Error.not_supported("A copy or move into missing parent folders is not simulated when the site policy does not always create them") if parents.any? && !state.profile.site_policy.always_mkdir_parents

        added = parents.size + entries.size - merged.size - replaced.size - (operation == "move" ? entries.size : 0)
        @namespace.reserve(state, added)
        copied = entries.sum { |record, _| operation == "copy" && record.is_a?(Version) ? record.size : 0 }
        raise Error.limit_exceeded(409, "Copying #{copied} bytes would pass the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{@bytes_in_use} are in use") if @bytes_in_use + copied > @max_bytes

        Relocation.new(operation:, entries:, merged:, replaced:, parents:)
      end

      # Applies a checked Relocation in one step and returns what it did.
      def apply(state, plan)
        copy = plan.operation == "copy"
        @namespace.add_parents(state, plan.parents)
        plan.replaced.each { |path| remove_file(state, state.files[path]) }
        plan.entries.each do |record, target|
          source = record.path
          if record.is_a?(Namespace::Folder)
            state.folders.delete(record.path) unless copy
            state.folders[target] = @namespace.relocated_folder(record, target, copy:) unless plan.merged.include?(target)
          elsif copy
            state.files[target] = Version.new(target, state.commits += 1, record.parts, record.provided_mtime)
            @bytes_in_use += record.size
          else
            state.files.delete(record.path)
            record.path = target
            state.files[target] = record
          end
          # A moved source's metadata ends with it; a folder merged into an existing one keeps the
          # destination's own metadata instead of taking the source's.
          metadata = copy ? state.file_metadata[source]&.dup : state.file_metadata.delete(source)
          state.file_metadata[target] = metadata if metadata && !plan.merged.include?(target)
        end
        files = plan.entries.map(&:first).grep(Version)
        { "type" => kind(plan.entries.first.first), "files" => files.size, "folders" => plan.entries.size - files.size, "bytes" => files.sum(&:size) }
      end

      def kind(entry)
        entry.is_a?(Namespace::Folder) ? "directory" : "file"
      end

      # The ZIP archive a stored file holds; Error.invalid_zip_file when Files.com could not read it.
      def archive(version)
        ZipArchive.new(version.parts.join)
      rescue ZipArchive::Invalid
        raise Error.invalid_zip_file
      end

      # Applies an unzip FileMigration in one step, or raises (failing it) before anything changes:
      # each file entry, or only `filename`, becomes a file at its path under the destination, with
      # the folders its path names created as parents, as Files.com extracts it. Folder entries
      # ("dir/") create nothing themselves. The failure messages are Files.com's. Files.com extracts
      # entries one at a time and keeps those it extracted before one fails; the simulator checks the
      # whole extraction first and then makes no change, which is not a claim about what Files.com keeps.
      def extract(state, migration)
        failure = ->(message) { Error.new(422, "processing-failure", "Processing Failure", message) }
        zip = @namespace.find(state, migration.path)
        raise failure.call("ZIP file not found: #{migration.path}") unless zip
        raise failure.call("ZIP source must be a file: #{migration.path}") if zip.is_a?(Namespace::Folder)

        archive = begin
          ZipArchive.new(zip.parts.join)
        rescue ZipArchive::Invalid
          raise failure.call("Unable to list contents of the .zip file. Does it exist and is it a valid ZIP archive?")
        end
        entries = archive.entries.to_h { |entry| [ entry.path, entry ] }
        filename = migration.params["filename"]
        if filename
          raise failure.call("File not found inside ZIP: #{filename}") unless entries.key?(filename)

          entries = entries.slice(filename)
        end
        targets = entries.reject { |name, _| name.end_with?("/") }.map do |name, entry|
          raise failure.call("Invalid ZIP entry path: #{name}") if name.start_with?("/") || name.split("/").include?("..")

          [ @namespace.request_path(migration.dest_path == Namespace::ROOT ? name : "#{migration.dest_path}/#{name}"), entry ]
        end
        parents = targets.flat_map { |target, _| @namespace.missing_parents(state, target) }.uniq.sort_by { |path| path.count("/") }
        clash = targets.map(&:first) & parents
        raise Error.not_supported("An archive holding both the file #{clash.first} and entries inside it is not simulated") if clash.any?

        replaced = targets.filter_map do |target, _|
          existing = @namespace.find(state, target) or next
          # The message a copy or move migration that meets an existing destination fails with.
          raise failure.call("The destination exists.") unless migration.params["overwrite"]
          raise Error.not_supported("Extracting onto the folder #{target} is not simulated") if existing.is_a?(Namespace::Folder)

          existing
        end
        # The whole extraction is admitted by its recorded sizes before any entry is read: an entry's
        # data is never longer than its recorded size (ZipArchive#data), so these are the bytes and
        # records it can add, and nothing is expanded for an extraction the limits refuse.
        @namespace.reserve(state, parents.size + targets.size - replaced.size)
        added = targets.sum { |_, entry| entry.size }
        raise Error.limit_exceeded(409, "Extracting #{added} bytes would pass the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{@bytes_in_use} are in use") if @bytes_in_use + added > @max_bytes

        data = targets.map do |target, entry|
          [ target, archive.data(entry) ]
        rescue ZipArchive::Invalid => e
          raise failure.call("zip_extract: #{e.message}")
        end
        @namespace.add_parents(state, parents)
        replaced.each { |version| remove_file(state, version) }
        data.each do |target, bytes|
          state.files[target] = Version.new(target, state.commits += 1, [ bytes.freeze ].freeze, nil)
          @bytes_in_use += bytes.bytesize
        end
        { "type" => "file", "files" => data.size, "folders" => parents.size, "bytes" => added }
      end

      # Makes a zip FileMigration's archive from the files as they are when it runs, and saves it as
      # its destination in one step, or raises (failing it) before anything changes. As in Rails'
      # FileMigration#perform_zip: an existing destination file fails the migration unless overwrite
      # is true, and is otherwise deleted before the stream reads the selection, so its old bytes are
      # never part of the new archive; a missing parent folder of the destination is created again
      # (mkdir_p); and the whole save is one processed operation, so files_moved is 1 once it
      # completes. The archive's entry count is journaled as "entries".
      #
      # Files.com streams the archive into the destination and does not promise to keep the old file
      # if that fails; the simulator builds the new archive first, without the old file, and then
      # replaces it, which is not a claim that a replacement is atomic. What Files.com's stream does
      # when a file cannot be read after it has started is not simulated.
      def create_zip(state, migration)
        destination = migration.dest_path
        existing = @namespace.find(state, destination)
        if existing
          # The message a copy or move migration that meets an existing destination fails with.
          raise Error.new(422, "processing-failure", "Processing Failure", "The destination exists.") unless migration.params["overwrite"]
          raise Error.not_supported("Replacing the folder #{destination} with a ZIP is not simulated") if existing.is_a?(Namespace::Folder)
        end
        parents = begin
          @namespace.missing_parents(state, destination)
        rescue Error
          raise Error.not_supported("A ZIP whose destination is now inside a file is not simulated")
        end

        entries = zip_entries(state, migration.params.fetch("paths"), without: existing)
        @namespace.reserve(state, parents.size + (existing ? 0 : 1))
        bound = ZipArchive.size_bound(entries.map { |name, version| [ name, version.size ] })
        raise Error.limit_exceeded(409, "A ZIP of up to #{bound} bytes would pass the transfer limit of #{@max_bytes} bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{@bytes_in_use} are in use") if @bytes_in_use + bound > @max_bytes

        bytes = ZipArchive.build(entries.map { |name, version| [ name, version.parts, version.provided_mtime || version.mtime ] }).freeze
        @namespace.add_parents(state, parents)
        remove_file(state, existing) if existing
        state.files[destination] = Version.new(destination, state.commits += 1, [ bytes ].freeze, nil)
        @bytes_in_use += bytes.bytesize
        { "type" => "file", "files" => 1, "entries" => entries.size, "folders" => parents.size, "bytes" => bytes.bytesize, "replaced" => !existing.nil? }
      end

      # [ entry name, Version ] for each file of the selection, taken in sorted order as
      # ZipDownload#contents takes it, with the current version of each selected file and the current
      # files inside each selected folder, leaving out `without` (the destination file an overwrite
      # has deleted). A selected file is named by its own name, and each file inside a selected
      # folder, at any depth, by the folder's name and its path inside it (ZipDownload's add_file and
      # add_tree_files). Folders are not entries, so an empty folder is left out; an empty file is
      # kept. Repeated names are numbered as files-protocol-server's ZIP stream numbers them
      # (#numbered). Refused as not simulated: a selected path that no longer exists, a selection of
      # the overwritten destination itself, and a selection that holds no file by now.
      def zip_entries(state, selection, without: nil)
        entries = selection.sort.flat_map do |path|
          raise Error.not_supported("A ZIP that selects the file it overwrites (#{path}) is not simulated") if without && path == without.path

          record = @namespace.find(state, path) or raise Error.not_supported("A ZIP whose selected path #{path} no longer exists when it is made is not simulated")
          name = path.split("/").last
          next [ [ name, record ] ] unless record.is_a?(Namespace::Folder)

          files = @namespace.subtree(state, path).last.reject { |version| version.equal?(without) }
          files.sort_by(&:path).map { |version| [ "#{name}/#{version.path.delete_prefix("#{path}/")}", version ] }
        end
        raise Error.not_supported("A ZIP whose selection holds no file when it is made is not simulated") if entries.empty?

        numbered(entries)
      end

      # The stream counts every entry name it has used, generated ones included: the second "f.txt"
      # becomes "f (1).txt", the third "f (2).txt", and a later "f (1).txt" becomes "f (1) (1).txt".
      # A generated name is not checked against names still to come, so it can repeat one; Java's
      # ZipOutputStream then refuses the duplicate entry. That, and a repeated name the stream cannot
      # number, fail it in a way whose outcome for the migration is not established, so the
      # simulator refuses both as not simulated.
      def numbered(entries)
        counts = {}
        named = entries.map do |name, version|
          if counts.key?(name)
            counts[name] += 1
            name = numbered_name(name, counts[name])
          end
          counts[name] = 0
          [ name, version ]
        end
        repeated = named.map(&:first).tally.find { |_, count| count > 1 }&.first
        raise Error.not_supported("A ZIP in which Files.com's entry numbering repeats the name #{repeated} is not simulated") if repeated

        named
      end

      def numbered_name(name, count)
        raise Error.not_supported("Numbering the repeated ZIP entry name #{name.inspect}, which holds a line break, is not simulated") if name.match?(/[\r\n\u0085\u2028\u2029]/)

        match = NUMBERED_EXTENSION.match(name)
        return "#{match[1]} (#{count})#{match[2]}" if match
        return "#{name} (#{count})" unless name.include?(".")

        raise Error.not_supported("A repeated ZIP entry name that Files.com's ZIP stream cannot number (#{name}) is not simulated")
      end

      # A FileMigration as FileMigrationEntity presents one: files_moved is the processed count, 0
      # until the migration has processed anything (FileMigration#files_moved), and the deprecated
      # files_total is always 0 for a FileMigration (only a region migration reports one). Copies,
      # moves and extractions report the files they moved or extracted, a ZIP its one saved archive.
      def present_migration(migration)
        { "id" => migration.id, "path" => migration.path, "dest_path" => migration.dest_path, "operation" => migration.operation, "status" => migration.status,
          "files_moved" => migration.files || 0, "files_total" => 0, "failure_message" => migration.failure_message }.compact.slice(*@migration_fields)
      end

      # Returns [ path, bytes, provided_mtime ] for a file fixture, after checking it.
      def fixture_file(state, spec)
        unknown = spec.keys - %w[path text base64 provided_mtime]
        raise Error.invalid_control("unknown fields: #{unknown.join(", ")}") if unknown.any?
        raise Error.invalid_control("give exactly one of text and base64") unless spec.key?("text") ^ spec.key?("base64")

        raise Error.invalid_control("path is missing") unless spec["path"].is_a?(String) && !spec["path"].empty?

        path = @namespace.request_path(spec["path"])
        raise Error.destination_exists if @namespace.find(state, path)

        bytes = spec.key?("text") ? spec["text"].to_s.b : spec["base64"].to_s.unpack1("m0")
        mtime = Coercion.utc_date_time(spec["provided_mtime"]) if spec.key?("provided_mtime")
        raise Error.invalid_control("provided_mtime is invalid") if mtime.equal?(Coercion::INVALID)

        parents = @namespace.missing_parents(state, path)
        @namespace.reserve(state, parents.size + 1)
        @namespace.add_parents(state, parents)
        [ path, bytes, mtime ]
      rescue ArgumentError
        raise Error.invalid_control("base64 is not valid strict Base64")
      end

      def fixture_error(label)
        yield
      rescue Error => e
        raise Error.new(e.status, e.type, e.title, "fixtures.#{label}: #{e.message}")
      end

      # The simulator refuses to start rather than ignore a modeled parameter that the schema no longer
      # declares, or check one whose declared type it does not understand.
      def require_modeled_params
        missing = MODELED_PARAMS.merge(ZIP_PARAMS.slice(*@zip_operations)).flat_map do |operation, names|
          names = names.reject { |name| OPTIONAL_PARAMS.fetch(operation, []).include?(name) && !@declared.fetch(operation).key?(name) }
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

      # Returns [ the name the path gives (see Namespace#request_path), the operation's parameters
      # converted to their schema types ], or raises before anything changes: 501 for a declared
      # parameter the simulator does not model, 422 for an invalid value, a required parameter (other
      # than the path) left out or a path parameter that disagrees with the path in the URL, then
      # whatever the path's check raises, since the API validates declared parameters before its action
      # reads the path. `path` is nil for an operation whose URL names no path (files.zip).
      #
      # A required parameter left out fails the API's parameter validation, whose errors it answers as a
      # bare bad-request with Grape's message ("destination is missing"). Grape checks only that the
      # parameter is there: one sent null or empty passes, and the operation judges it after the path.
      def accepted(operation, path, params, root: false)
        supplied = params.slice(*declared_names(operation)).compact
        unmodeled = supplied.keys - MODELED_PARAMS.fetch(operation) { ZIP_PARAMS.fetch(operation) } - OPTIONAL_PARAMS.fetch(operation, [])
        raise Error.not_supported("Simulation does not support these parameters: #{unmodeled.join(", ")}") if unmodeled.any?

        values = supplied.to_h { |key, value| [ key, convert(operation, key, value) ] }
        invalid = values.select { |key, value| value.equal?(Coercion::INVALID) || (key == "size" && value.negative?) }.keys
        raise Error.bad_request(invalid.map { |key| "#{key} is invalid" }.join(", ")) if invalid.any?

        missing = @declared.fetch(operation).find { |key, rule| rule["required"] && key != "path" && !params.key?(key) }
        raise Error.bad_request("#{missing.first} is missing") if missing
        raise Error.bad_request("path must match the path in the URL") if values.key?("path") && values["path"] != path

        name = @namespace.request_path(path, root:, route: FOLDER_ROUTES.include?(operation) ? :folder : :file) unless path.nil?
        [ name, values ]
      end

      def convert(operation, name, value)
        case name
        when "etags" then value # checked against the upload's parts by #listed_parts
        when "provided_mtime" then Coercion.utc_date_time(value)
        when "custom_metadata" then custom_metadata_param(value)
        else
          converter = Coercion.for(@declared.fetch(operation).fetch(name))
          converter = :dotnet_boolean if converter == :boolean && DOTNET_BOOLEAN_OPERATIONS.include?(operation)
          converter = :int64 if converter == :int32 && BYTE_COUNTS.fetch(operation, []).include?(name)
          Coercion.public_send(converter, Coercion.request_array(converter, value))
        end
      end

      # What the API's destination helper refuses once it has normalized a destination (copy, move,
      # unzip and zip all read it): any of its folders, every name but the last, ending in whitespace.
      # A last name ending in whitespace is not refused by that rule.
      def refuse_trailing_whitespace(destination)
        @namespace.refuse_trailing_whitespace(File.dirname(destination))
      end

      # custom_metadata as the API's parameter coercion admits it (FileEntity's {String => String}
      # through its strict hash coercer): an object whose values are strings or null, kept as sent. Any
      # other value, such as a number, a boolean, an object or an array, is invalid (422 bad-request),
      # before the path is looked up; nothing is converted to text.
      def custom_metadata_param(value)
        metadata = Coercion.object(value)
        return metadata if metadata.equal?(Coercion::INVALID)

        metadata.each_value.all? { |item| item.nil? || item.is_a?(String) } ? metadata : Coercion::INVALID
      end

      # MetadataDm#validate_custom_metadata, as PATCH /files/{path} reaches it: the update assigns the
      # whole custom_metadata Hash, and the model refuses to save one with a key or a non-null value
      # longer than its limit (each key in order, its key then its value) or with too many keys, all
      # its errors together (422 model-save-error).
      def refuse_unsaved_metadata(metadata)
        return unless metadata.is_a?(Hash)

        failures = metadata.flat_map do |key, value|
          [ ([ "custom_metadata", "key_too_long", "Custom metadata key is too long" ] if key.length > CUSTOM_METADATA_MAX_KEY_LENGTH),
            ([ "custom_metadata", "value_too_long", "Custom metadata value is too long" ] if value && value.length > CUSTOM_METADATA_MAX_VALUE_LENGTH) ].compact
        end
        failures << [ "custom_metadata", "too_many_keys", "Custom metadata has too many keys" ] if metadata.size > CUSTOM_METADATA_MAX_KEYS
        raise Error.model_save_error(failures) if failures.any?
      end

      # A write whose parent folder is missing, on a site that does not always create parent folders
      # (Profile::SitePolicy), is refused 404 not-found unless it sends mkdir_parents true.
      def refuse_missing_parents(state, parents, values)
        return if parents.empty? || state.profile.site_policy.always_mkdir_parents || values["mkdir_parents"] == true

        raise Error.not_found
      end

      # The parent folders a file write at path must create. Raises before anything changes when a
      # folder holds the name: finalizing onto it is refused as the API refuses it, and beginning an
      # upload there is not simulated.
      def file_parents(state, path, publishing:)
        if @namespace.find(state, path).is_a?(Namespace::Folder)
          raise Error.destination_exists if publishing

          raise Error.not_supported("Uploading a file where the folder #{path} is is not simulated")
        end
        @namespace.missing_parents(state, path)
      end

      # Without etags, the parts are the ones the upload actually received, as Files.com native storage
      # finds an upload's parts itself. The simulator does this only for a sequential upload of known
      # size: size is sent and the received parts are numbered 1 to N. An empty file is one empty part.
      def received_parts(values, upload)
        raise Error.not_supported("Finalizing without etags is simulated only for an upload of known size; send size, or list every part in etags") unless values.key?("size")

        numbers = upload.parts.keys.sort
        raise Error.file_not_uploaded if numbers.empty?
        raise Error.not_supported("Finalizing without etags is simulated only for parts numbered 1 to N; this upload received part(s) #{numbers.join(", ")}") unless numbers == (1..numbers.size).to_a

        numbers
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

      # Checks parts first to first + count - 1 by their ends, before any of them is issued.
      def check_part_range(first, count)
        check_part_number(first)
        check_part_number(first + count - 1)
      end

      # A part's FileUploadPart. Under a serial or parallel profile its partsize is bound the first time
      # it is issued, so renewing its URL never changes it, and next_partsize announces the partsize of
      # the next part, which partsize_changes may make different.
      def upload_part(state, upload, number, origin)
        ref = Token.encode("upload", @instance, state.epoch, upload.id)
        upload_profile = state.profile.upload
        profile = advertised(upload_profile)
        unless upload_profile.legacy?
          profile["partsize"] = upload.plan[number] ||= upload_profile.partsize_for(number)
          profile["next_partsize"] = planned_partsize(upload, upload_profile, number + 1)
        end
        profile.merge(
          "ref" => ref, "part_number" => number, "next_partsize" => profile.fetch("next_partsize", profile["partsize"]),
          "upload_uri" => transfer_url(state, "PUT", origin, "upload/#{ref}/#{number}"),
          "expires" => (Time.now.utc + UPLOAD_URL_LIFETIME).strftime("%FT%TZ"), "path" => upload.path
        ).slice(*@part_fields)
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

      # Returns [ request or nil, lookup ]: the request this simulator issued with that ID and still
      # holds ("found"), or why there is none: "evicted" (newer requests took its place),
      # "earlier_reset" (issued before the latest reset, as the producer lost its requests when it
      # restarted) or "not_issued".
      def find_download_request(state, id)
        values = Token.values(id, "download-request", @instance)
        epoch, number = values.map { |value| Integer(value, 10) } if values&.size == 2 && values.all? { |value| value.match?(/\A(?:0|[1-9][0-9]*)\z/) }
        return [ nil, "not_issued" ] unless number
        return [ nil, "earlier_reset" ] if epoch < state.epoch
        return [ nil, "not_issued" ] unless epoch == state.epoch && number.between?(1, state.last_download_request_id)

        request = state.download_requests[number]
        request ? [ request, "found" ] : [ nil, "evicted" ]
      end

      # The status data the producer held for a request, less its timestamps (whose wire encoding was
      # not established) and its remote server's log context: the IDs, the chosen status and the bytes
      # the response was made from, none while the status is started, as for a request still streaming.
      def download_request_data(state, request)
        status = state.profile.download.request_status.fetch("status")
        { "id" => download_request_id(state, request.number), "type" => "file_download", "bytes_transferred" => (request.bytes unless status == "started"),
          "file_transfer_id" => request.download_token, "status" => status, "method" => "get" }
      end

      def download_request_id(state, number)
        Token.encode("download-request", @instance, state.epoch, number)
      end
    end
  end
end
