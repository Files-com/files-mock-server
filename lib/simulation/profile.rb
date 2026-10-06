module FilesMockServer
  module Simulation
    # Simulation policies a reset chooses (POST /__files_mock/v1/reset with "profile"), kept until
    # the next reset. They select among behaviors the simulator implements; they are statements
    # about this simulated site, never claims about what a particular real site does.
    class Profile
      # "completed": a copy or move is applied in its request and answers {"status": "completed"},
      # as a recorded Files.com response for a single-file move does. "pending": it answers
      # {"status": "pending", "file_migration_id"} and is applied only when its FileMigration is
      # polled to completion (see Files#migration).
      FILE_ACTIONS = %w[completed pending].freeze
      FIELDS = %w[file_actions upload download signed_urls list_cursors site_policy].freeze
      # list_cursors: "opaque" cursors are hexadecimal; "special-characters" cursors start with
      # SPECIAL_CURSOR, which holds a space, +, &, =, a percent escape and #, so a client that
      # re-encodes or decodes a cursor more than once sends one the list refuses (422 invalid-cursor).
      # Cursors travel in response headers, so they stay ASCII.
      LIST_CURSORS = %w[opaque special-characters].freeze
      SPECIAL_CURSOR = "2:a+b &x=y%25#".freeze
      # Where each choice comes from: a simulation policy, or a contract the simulator follows.
      BASIS = {
        "file_actions" => "completed: a recorded Files.com move response; pending: simulation policy over the FileAction and FileMigration schema",
        "upload.mode" => "legacy: the previous simulator advertisement, unchecked; serial and parallel: simulation policy that checks the FileUploadPart parallel_parts and retry_parts meanings",
        "upload.variable_part_limits, upload.part_offset_query, upload.upload_target_class" => "the combined adaptive schema (06a437e2), accepted for local qualification and not deployed",
        "upload.max_concurrent_parts" => "simulation policy, a throttling provider's 503 with Retry-After; not a provider limit",
        "signed_urls" => "simulation policy modeled on AWS SigV4 presigned URLs, with a sentinel credential",
        "download.identity" => "contract_v1: the parent-adopted download identity contract; its parameters are declared by the local Rails export b8129459, not by the production pin 8e7cdc",
        "download.request_status" => "the historical Files Sync Worker protocol at 9073d2bc, which the Go SDK's status consumer was written against: the header on a successful GET, " \
                                     "the status at the download URL joined with the ID, HTTP 200 with http_code for any status it holds and 404 download_request_not_found; " \
                                     "the status is a fixture the reset chooses, not a simulated transfer lifecycle, and whether the protocol is still deployed is not established. " \
                                     "header_on_failure: simulation policy, since the captured producer source gives no ID to a response that fails before it streams; " \
                                     "what a response that failed later carried is not established",
        "download.size" => "withheld: the historical producer's answer for a remote whose size cannot be trusted (a whole-file 200 without Content-Length); a range's \"*\" total " \
                           "is simulation policy, since the producer's range header for that case was not captured",
        "site_policy.always_mkdir_parents" => "true: simulation policy, as older simulators behaved; false: the Files.com site setting's default, with the API's find_folder rule for a missing parent folder",
      }.freeze
      # signed_urls: upload and download URLs carry a synthetic AWS SigV4-style presigned query (a
      # sentinel credential, X-Amz-Date, X-Amz-Expires and a signature over the exact query bytes), and
      # a transfer whose query differs in any byte is refused with 403 SignatureDoesNotMatch, as a
      # presigned storage URL is. Its lifetime is advertised, not enforced; expired_url faults expire URLs.
      SIGNED_URL_FIELDS = %w[lifetime].freeze
      MAX_URL_LIFETIME = 604_800

      # How uploads advertise and check their parts.
      #
      # "legacy" (the default) keeps the advertisement older simulators made (one part at a time, in
      # order, retries allowed) without checking it, and lets parts have any size.
      # "serial" and "parallel" advertise parallel_parts false or true and check what they advertise:
      # a serial upload admits one part at a time, in order; a parallel one admits parts in any order,
      # at most max_concurrent_parts at once across all uploads (more are answered 503 with
      # Retry-After, as a throttling provider does). Both check retry_parts, part sizes against
      # variable_part_limits when it is set, and part offsets when part_offset_query is on.
      # partsize and partsize_changes only choose the partsize and next_partsize parts are issued
      # with: hints a client may follow, never sizes its parts must hold.
      class Upload
        MODES = %w[legacy serial parallel].freeze
        FIELDS = %w[mode retry_parts partsize partsize_changes variable_part_limits part_offset_query upload_target_class max_concurrent_parts throttle_retry_after].freeze
        LIMITS = %w[min_nonfinal_bytes max_part_bytes max_parts max_file_bytes].freeze
        TARGET_CLASSES = %w[s3 agent_fiw generic].freeze
        # FileUploadPart fields a setting is advertised in; the server's schema must declare them.
        ADVERTISED_IN = { "variable_part_limits" => "variable_part_limits", "part_offset_query" => "part_offset_query", "upload_target_class" => "upload_target_class" }.freeze
        MAX_CONCURRENT_PARTS = 64
        MAX_RETRY_AFTER = 60

        attr_reader :mode, :retry_parts, :partsize, :partsize_changes, :variable_part_limits, :part_offset_query, :upload_target_class, :max_concurrent_parts,
                    :throttle_retry_after

        def initialize(spec, part_fields:, default_partsize:, max_body_bytes:)
          raise Error.invalid_control("profile.upload must be a JSON object") unless spec.is_a?(Hash)

          unknown = spec.keys - FIELDS
          raise Error.invalid_control("Unknown profile.upload fields: #{unknown.join(", ")}") if unknown.any?

          @mode = spec.fetch("mode", "legacy")
          raise Error.invalid_control("profile.upload.mode must be one of: #{MODES.join(", ")}") unless MODES.include?(@mode)
          raise Error.invalid_control("profile.upload settings other than mode need mode serial or parallel") if legacy? && spec.size > (spec.key?("mode") ? 1 : 0)

          missing = ADVERTISED_IN.select { |setting, field| spec.key?(setting) && !part_fields.include?(field) }.values
          raise Error.invalid_control("This server's schema does not declare FileUploadPart #{missing.join(", ")}, so it cannot advertise them; generate the server from a schema that does") if missing.any?

          @retry_parts = boolean(spec, "retry_parts", true)
          @part_offset_query = boolean(spec, "part_offset_query", false)
          @partsize = spec.fetch("partsize", default_partsize)
          raise Error.invalid_control("profile.upload.partsize must be a whole number from 1 to #{max_body_bytes} (FILES_MOCK_MAX_BODY_BYTES)") unless @partsize.is_a?(Integer) && @partsize.between?(1, max_body_bytes)

          @partsize_changes = changes(spec.fetch("partsize_changes", []), max_body_bytes)
          @variable_part_limits = limits(spec["variable_part_limits"], max_body_bytes) if spec.key?("variable_part_limits")
          @upload_target_class = spec["upload_target_class"]
          raise Error.invalid_control("profile.upload.upload_target_class must be one of: #{TARGET_CLASSES.join(", ")}") unless @upload_target_class.nil? || TARGET_CLASSES.include?(@upload_target_class)

          @max_concurrent_parts = spec["max_concurrent_parts"]
          raise Error.invalid_control("profile.upload.max_concurrent_parts applies to mode parallel") if @max_concurrent_parts && @mode != "parallel"
          raise Error.invalid_control("profile.upload.max_concurrent_parts must be a whole number from 1 to #{MAX_CONCURRENT_PARTS}") unless @max_concurrent_parts.nil? || (@max_concurrent_parts.is_a?(Integer) && @max_concurrent_parts.between?(1, MAX_CONCURRENT_PARTS))

          @throttle_retry_after = spec.fetch("throttle_retry_after", 1)
          raise Error.invalid_control("profile.upload.throttle_retry_after applies with max_concurrent_parts") if spec.key?("throttle_retry_after") && @max_concurrent_parts.nil?
          raise Error.invalid_control("profile.upload.throttle_retry_after must be a whole number of seconds from 0 to #{MAX_RETRY_AFTER}") unless @throttle_retry_after.is_a?(Integer) && @throttle_retry_after.between?(0, MAX_RETRY_AFTER)
        end

        def legacy?
          @mode == "legacy"
        end

        # The partsize parts numbered `number` are issued with: partsize, or the last change whose
        # from_part is at most `number`.
        def partsize_for(number)
          @partsize_changes.reverse.find { |change| change["from_part"] <= number }&.fetch("partsize") || @partsize
        end

        def parallel?
          @mode == "parallel"
        end

        def as_json
          { "mode" => @mode, "retry_parts" => @retry_parts, "partsize" => @partsize, "partsize_changes" => (@partsize_changes unless @partsize_changes.empty?),
            "variable_part_limits" => @variable_part_limits, "part_offset_query" => @part_offset_query,
            "upload_target_class" => @upload_target_class, "max_concurrent_parts" => @max_concurrent_parts, "throttle_retry_after" => (@throttle_retry_after if @max_concurrent_parts) }.compact
        end

        private

        def boolean(spec, name, default)
          value = spec.fetch(name, default)
          raise Error.invalid_control("profile.upload.#{name} must be true or false") unless [ true, false ].include?(value)

          value
        end

        # partsize_changes: [{ "from_part", "partsize" }, ...] with increasing from_part, each a later
        # part than the first, so parts already issued keep their partsize and only later parts change.
        def changes(spec, max_body_bytes)
          valid = spec.is_a?(Array) && spec.all? { |change| change.is_a?(Hash) && change.keys.sort == %w[from_part partsize] }
          raise Error.invalid_control("profile.upload.partsize_changes must be a list of { \"from_part\", \"partsize\" }") unless valid

          parts = spec.map { |change| change["from_part"] }
          raise Error.invalid_control("profile.upload.partsize_changes from_part values must be increasing whole numbers from 2") unless parts.all? { |part| part.is_a?(Integer) && part >= 2 } && parts == parts.uniq.sort
          raise Error.invalid_control("profile.upload.partsize_changes partsize must be a whole number from 1 to #{max_body_bytes} (FILES_MOCK_MAX_BODY_BYTES)") unless spec.all? { |change| change["partsize"].is_a?(Integer) && change["partsize"].between?(1, max_body_bytes) }

          spec.map { |change| change.slice("from_part", "partsize") }
        end

        def limits(spec, max_body_bytes)
          raise Error.invalid_control("profile.upload.variable_part_limits must be a JSON object with #{LIMITS.join(", ")}") unless spec.is_a?(Hash) && spec.keys.sort == LIMITS.sort
          raise Error.invalid_control("profile.upload.variable_part_limits values must be positive whole numbers") unless spec.values.all? { |value| value.is_a?(Integer) && value.positive? }
          raise Error.invalid_control("profile.upload.variable_part_limits.min_nonfinal_bytes must not exceed max_part_bytes") if spec["min_nonfinal_bytes"] > spec["max_part_bytes"]
          raise Error.invalid_control("profile.upload.variable_part_limits.max_part_bytes must not exceed #{max_body_bytes} (FILES_MOCK_MAX_BODY_BYTES)") if spec["max_part_bytes"] > max_body_bytes

          LIMITS.to_h { |name| [ name, spec[name] ] }
        end
      end

      # How downloads identify the version they send, and what their storage responses offer.
      #
      # identity: "absent" (the default): download URLs name a version, and one whose file has
      # changed is refused (409 download_source_changed), but no identity is offered, as a server
      # without the download identity contract answers. "contract_v1": files.download also takes
      # with_download_identity and expected_download_identity and returns download_identity,
      # following the parent-adopted download identity contract. The local Rails export b8129459
      # declares both parameters; the production pin 8e7cdc declares neither (see README.md).
      #
      # request_status: absent (the default), or { "status", "header_on_failure" }, the historical
      # Files Sync Worker protocol (Files#download_request_status): each successful storage download
      # response carries an X-Files-Download-Request-Id, and GET on the download URL joined with that
      # ID answers the status the reset chose. With header_on_failure true, a failed storage response
      # carries one as well, which the captured producer source does not do for a response that fails
      # before it streams (later failures are not established). Absent, the joined path stays unrouted.
      #
      # size: "sent" (the default) or "withheld": a whole-file 200 without Content-Length (Puma sends
      # it chunked to an HTTP/1.1 client) and a range 206 whose Content-Range total is "*".
      class Download
        IDENTITIES = %w[absent contract_v1].freeze
        FIELDS = %w[identity request_status size].freeze
        REQUEST_STATUSES = %w[completed started failed error].freeze
        REQUEST_STATUS_FIELDS = %w[status header_on_failure].freeze
        SIZES = %w[sent withheld].freeze

        attr_reader :identity, :request_status, :size

        def initialize(spec)
          raise Error.invalid_control("profile.download must be a JSON object") unless spec.is_a?(Hash)

          unknown = spec.keys - FIELDS
          raise Error.invalid_control("Unknown profile.download fields: #{unknown.join(", ")}") if unknown.any?

          @identity = spec.fetch("identity", "absent")
          raise Error.invalid_control("profile.download.identity must be one of: #{IDENTITIES.join(", ")}") unless IDENTITIES.include?(@identity)

          @request_status = checked_request_status(spec["request_status"]) if spec.key?("request_status")
          @size = spec.fetch("size", "sent")
          raise Error.invalid_control("profile.download.size must be one of: #{SIZES.join(", ")}") unless SIZES.include?(@size)
        end

        def request_status?
          !@request_status.nil?
        end

        def header_on_failure?
          request_status? && @request_status.fetch("header_on_failure")
        end

        def size_withheld?
          @size == "withheld"
        end

        # A reset that chooses neither request_status nor a withheld size reports what it always did.
        def as_json
          { "identity" => @identity, "request_status" => @request_status, "size" => (@size if size_withheld?) }.compact
        end

        private

        def checked_request_status(spec)
          raise Error.invalid_control("profile.download.request_status must be a JSON object") unless spec.is_a?(Hash)

          unknown = spec.keys - REQUEST_STATUS_FIELDS
          raise Error.invalid_control("Unknown profile.download.request_status fields: #{unknown.join(", ")}") if unknown.any?

          status = spec.fetch("status", "completed")
          raise Error.invalid_control("profile.download.request_status.status must be one of: #{REQUEST_STATUSES.join(", ")}") unless REQUEST_STATUSES.include?(status)

          header_on_failure = spec.fetch("header_on_failure", false)
          raise Error.invalid_control("profile.download.request_status.header_on_failure must be true or false") unless [ true, false ].include?(header_on_failure)

          { "status" => status, "header_on_failure" => header_on_failure }.freeze
        end
      end

      # The site's "always create parent folders" setting (Site always_mkdir_parents). true, the
      # default: every write creates the parent folders it is missing. false, the setting's default
      # on a Files.com site: an upload (begin_upload and finalize) or a folder creation whose parent
      # folder is missing is refused 404 not-found unless the request sends mkdir_parents true, as the
      # API's find_folder does. Unzip creates its destination folder either way, as the API does; a copy
      # or move whose destination is missing parent folders is not simulated under false.
      class SitePolicy
        FIELDS = %w[always_mkdir_parents].freeze

        attr_reader :always_mkdir_parents

        def initialize(spec)
          raise Error.invalid_control("profile.site_policy must be a JSON object") unless spec.is_a?(Hash)

          unknown = spec.keys - FIELDS
          raise Error.invalid_control("Unknown profile.site_policy fields: #{unknown.join(", ")}") if unknown.any?

          @always_mkdir_parents = spec.fetch("always_mkdir_parents", true)
          raise Error.invalid_control("profile.site_policy.always_mkdir_parents must be true or false") unless [ true, false ].include?(@always_mkdir_parents)
        end

        def as_json
          { "always_mkdir_parents" => @always_mkdir_parents }
        end
      end

      attr_reader :file_actions, :upload, :download, :url_lifetime, :list_cursors, :site_policy

      # context: { part_fields:, default_partsize:, max_body_bytes: } from the server's schema and limits.
      def self.default(**)
        new({}, **)
      end

      def initialize(spec, part_fields: [], default_partsize: 1, max_body_bytes: 1)
        raise Error.invalid_control("profile must be a JSON object") unless spec.is_a?(Hash)

        unknown = spec.keys - FIELDS
        raise Error.invalid_control("Unknown profile fields: #{unknown.join(", ")}") if unknown.any?

        @file_actions = spec.fetch("file_actions", "completed")
        raise Error.invalid_control("profile.file_actions must be one of: #{FILE_ACTIONS.join(", ")}") unless FILE_ACTIONS.include?(@file_actions)

        @upload = Upload.new(spec.fetch("upload", {}), part_fields:, default_partsize:, max_body_bytes:)
        @download = Download.new(spec.fetch("download", {}))
        @site_policy = SitePolicy.new(spec.fetch("site_policy", {}))
        @url_lifetime = signed_urls(spec["signed_urls"]) if spec.key?("signed_urls")
        @list_cursors = spec.fetch("list_cursors", "opaque")
        raise Error.invalid_control("profile.list_cursors must be one of: #{LIST_CURSORS.join(", ")}") unless LIST_CURSORS.include?(@list_cursors)
        raise Error.invalid_control("profile.signed_urls cannot be combined with part_offset_query: a presigned storage URL signs its whole query") if @url_lifetime && @upload.part_offset_query
      end

      def signed_urls?
        !@url_lifetime.nil?
      end

      # The cursor a list sends for a handle, and the handle a received cursor carries (nil when it
      # does not carry one, which makes it invalid).
      def cursor(token)
        @list_cursors == "special-characters" ? "#{SPECIAL_CURSOR}#{token}" : token
      end

      def token_of(cursor)
        return cursor unless @list_cursors == "special-characters"

        cursor.delete_prefix(SPECIAL_CURSOR) if cursor.is_a?(String) && cursor.start_with?(SPECIAL_CURSOR)
      end

      def as_json
        { "file_actions" => @file_actions, "upload" => @upload.as_json, "download" => @download.as_json, "signed_urls" => ({ "lifetime" => @url_lifetime } if signed_urls?),
          "list_cursors" => @list_cursors, "site_policy" => @site_policy.as_json }.compact
      end

      private

      def signed_urls(spec)
        raise Error.invalid_control("profile.signed_urls must be a JSON object") unless spec.is_a?(Hash)

        unknown = spec.keys - SIGNED_URL_FIELDS
        raise Error.invalid_control("Unknown profile.signed_urls fields: #{unknown.join(", ")}") if unknown.any?

        lifetime = spec.fetch("lifetime", 900)
        raise Error.invalid_control("profile.signed_urls.lifetime must be a whole number of seconds from 1 to #{MAX_URL_LIFETIME}") unless lifetime.is_a?(Integer) && lifetime.between?(1, MAX_URL_LIFETIME)

        lifetime
      end
    end
  end
end
