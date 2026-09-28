require "date"
require "digest"
require "json"
require "rack"
require "securerandom"
require "socket"
require "uri"

require_relative "simulation/error"
require_relative "simulation/limits"
require_relative "simulation/coercion"
require_relative "simulation/token"
require_relative "simulation/path_comparison"
require_relative "simulation/fault_rules"
require_relative "simulation/state"
require_relative "simulation/users"
require_relative "simulation/files"

module FilesMockServer
  # Opt-in (FILES_MOCK_MODE=simulation) stateful simulation of a small, advertised subset of the
  # Files.com REST API. Every other API request gets a 501 response, so a test cannot mistake an
  # unmodeled call for a pass. README.md documents the contract.
  module Simulation
    CONTRACT_VERSION = 1
    API_PREFIX = "/api/rest/v1".freeze
    CONTROL_PREFIX = "/__files_mock/v1".freeze
    # Upload and download URLs that the file operations return. They are not Files.com API paths.
    TRANSFER_PREFIX = "/__files_mock/transfer".freeze
    # Simulated operations. "fault_match" names the request values a fault rule may match on.
    OPERATIONS = [
      { "id" => "users.create", "method" => "POST", "path" => "/users", "fault_match" => "username" },
      { "id" => "users.list", "method" => "GET", "path" => "/users", "fault_match" => nil },
      { "id" => "users.find", "method" => "GET", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.update", "method" => "PATCH", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.delete", "method" => "DELETE", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "files.begin_upload", "method" => "POST", "path" => "/file_actions/begin_upload/{path}", "fault_match" => "path" },
      { "id" => "files.finalize_upload", "method" => "POST", "path" => "/files/{path}", "fault_match" => "path" },
      { "id" => "files.download", "method" => "GET", "path" => "/files/{path}", "fault_match" => "path" },
      { "id" => "files.metadata", "method" => "GET", "path" => "/file_actions/metadata/{path}", "fault_match" => "path" }
    ].freeze
    # Byte transfers to the upload_uri and download_uri that the file operations return.
    TRANSFER_OPERATIONS = [
      { "id" => "transfers.upload_part", "method" => "PUT", "path" => "/upload/{ref}/{part}", "fault_match" => %w[path part] },
      { "id" => "transfers.download", "method" => "GET", "path" => "/download/{version}", "fault_match" => "path" }
    ].freeze
    FAULT_MATCH_KEYS = (OPERATIONS + TRANSFER_OPERATIONS).to_h { |operation| [ operation["id"], operation["fault_match"] ] }.freeze
    # A {path} placeholder takes the rest of the request path, slashes included; the others take one segment.
    ROUTES = { API_PREFIX => OPERATIONS, TRANSFER_PREFIX => TRANSFER_OPERATIONS }.flat_map { |prefix, operations|
      operations.map do |operation|
        pattern = Regexp.escape(prefix + operation["path"]).gsub(/\\\{(\w+)\\\}/) { "(?<#{$1}>#{$1 == "path" ? ".+" : "[^/]+"})" }
        [ operation["method"], Regexp.new("\\A#{pattern}\\z"), operation["id"] ]
      end
    }.freeze
    ENTITIES = { Users::RESOURCE => "User", "files" => "File", "file_upload_parts" => "FileUploadPart" }.freeze
    # Swagger-derived parameter and field metadata, generated beside this file.
    SCHEMA_PATH = File.expand_path("simulation/schema.json", __dir__)

    # One simulator. Its state belongs to this instance alone, and every access to it holds @lock.
    class App
      # transfer_origin is FILES_MOCK_TRANSFER_ORIGIN: the origin clients reach this server at, for
      # upload and download URLs, when it differs from the address the server listens on.
      def initialize(limits: Limits.new, schema_path: SCHEMA_PATH, transfer_origin: nil)
        @limits = limits
        schema = JSON.parse(File.read(schema_path))
        require_complete(schema)
        @schema_sha256 = Digest::SHA256.file(schema_path).hexdigest
        @swagger_operation_ids = schema.fetch("operations").transform_values { |operation| operation.fetch("operation_id") }
        @version = File.read(File.expand_path("../_VERSION", __dir__)).strip
        @transfer_origin = validated_origin(transfer_origin)
        @users = Users.new(schema, max_records: limits.max_records)
        @instance = SecureRandom.hex(6)
        @lock = Mutex.new
        @files = Files.new(schema, limits:, instance: @instance, lock: @lock)
        @state = State.new(0, limits, FAULT_MATCH_KEYS)
      end

      def call(env)
        request = Rack::Request.new(env)
        status, headers, body = dispatch(request)
        # Rack forbids a body in a HEAD response. HEAD is not simulated, so it keeps its error status.
        [ status, headers, request.head? ? [] : body ]
      end

      private

      # A server generated from a Swagger document without the simulated operations still works in
      # legacy mode, but the simulator refuses to start rather than serve an incomplete contract.
      def require_complete(schema)
        missing = OPERATIONS.reject { |operation| schema.fetch("operations").key?(operation["id"]) }.map { |operation| "#{operation["method"]} #{API_PREFIX}#{operation["path"]}" }
        missing += ENTITIES.reject { |resource, _name| schema.fetch("entities").key?(resource) }.map { |_resource, name| "the #{name} entity" }
        return if missing.empty?

        raise ArgumentError, "Simulation mode needs #{missing.join(", ")}, which the Swagger document this server was generated from does not define. " \
                             "Regenerate the server from the Files.com API schema, or leave FILES_MOCK_MODE unset to use the legacy server."
      end

      def dispatch(request)
        if request.path_info.start_with?("#{CONTROL_PREFIX}/")
          control(request)
        elsif request.path_info.start_with?("#{API_PREFIX}/", "#{TRANSFER_PREFIX}/")
          simulate(request)
        else
          Error.not_found.to_rack
        end
      end

      # Reads the request outside the lock, then applies the reset-epoch check, fault matching,
      # validation and the state change as one atomic step under it. A read failure is deferred into
      # that step instead of being returned early, so every API and transfer request, including a
      # malformed one, gets a journal sequence number. A request that entered the Rack application
      # before a reset is refused rather than applied to the new state.
      def simulate(request)
        arrival_epoch = @lock.synchronize { @state.epoch }
        operation, target = route(request, arrival_epoch)
        begin
          input = read_input(request, operation) if operation
        rescue Error => e
          read_error = e
        end

        @lock.synchronize do
          state = @state
          state.request_count += 1
          seq = state.request_count
          fault = nil
          response, outcome = begin
            raise Error.stale_request unless state.epoch == arrival_epoch
            raise read_error if read_error
            raise Error.not_supported("#{request.request_method} #{printable(request.path_info)} is not simulated; GET #{CONTROL_PREFIX}/ready lists the supported operations") unless operation

            fault = state.faults.consume(operation, fault_match_values(state, operation, target, input), seq)
            raise Error.injected_fault(fault) if fault

            perform(state, request, operation, target, input)
          rescue Error => e
            [ e.to_rack, {} ]
          end
          entry = { "seq" => seq, "epoch" => state.epoch, "method" => request.request_method, "path" => printable(request.path_info),
                    "operation" => operation, "id" => target["id"], "fault_id" => fault&.id, "status" => response.first }
          state.journal.record(entry.merge(target.slice("upload", "part", "version"), outcome))
          response
        end
      ensure
        @lock.synchronize { @files.release(input) } if input.is_a?(Files::Received)
      end

      # Returns [ operation ID, target ]. The target holds the route's values: a record ID or part number
      # (nil unless a positive integer), a file path decoded exactly once, and the upload or version
      # number in a handle this simulator issued in the epoch the request arrived in (else nil).
      def route(request, epoch)
        ROUTES.each do |method, pattern, operation|
          next unless method == request.request_method && (match = pattern.match(request.path_info))

          return [ operation, route_target(match.named_captures, epoch) ]
        end
        [ nil, {} ]
      end

      def route_target(captures, epoch)
        captures.each_with_object({}) do |(name, value), target|
          case name
          when "id", "part" then target[name] = value.match?(/\A[1-9][0-9]*\z/) ? Integer(value, 10) : nil
          when "path" then target[name] = Rack::Utils.unescape_path(value).force_encoding(Encoding::UTF_8)
          when "ref" then target.update("ref" => value, "upload" => @files.upload_number(value, epoch))
          when "version" then target[name] = @files.version_number(value, epoch)
          end
        end
      end

      # Returns [ Rack response, journal fields ]. An entry names the record ID from the path, except
      # that a create names the ID it allocated. File and transfer entries name the upload, part and
      # version they used, with byte counts and SHA-256 digests; never content or credentials.
      def perform(state, request, operation, target, input)
        case operation
        when "users.create"
          user = @users.create(state, input)
          [ json(201, user), { "id" => user["id"] } ]
        when "users.list"
          users, next_cursor = @users.list(state, input, @instance)
          [ json(200, users, next_cursor ? { "x-files-cursor" => next_cursor, "x-files-cursor-next" => next_cursor } : {}), {} ]
        when "users.find"
          [ json(200, @users.find(state, target["id"])), {} ]
        when "users.update"
          [ json(200, @users.update(state, target["id"], input)), {} ]
        when "users.delete"
          @users.delete(state, target["id"], input)
          [ [ 204, {}, [] ], {} ]
        when "files.begin_upload"
          upload, part = @files.begin_upload(state, target["path"], input, transfer_origin(request))
          [ json(200, [ part ]), { "upload" => upload.id } ]
        when "transfers.upload_part"
          part = @files.store_part(state, target, input)
          [ [ 200, { "etag" => %("#{part.etag}") }, [] ], { "bytes" => part.bytes.bytesize, "sha256" => part.etag } ]
        when "files.finalize_upload"
          status, upload, version = @files.finalize_upload(state, target["path"], input)
          [ json(status, @files.present(version)), { "upload" => upload.id, "version" => version.number, "bytes" => version.size, "sha256" => version.sha256 } ]
        when "files.download"
          version, download_uri = @files.download(state, target["path"], input, transfer_origin(request))
          [ json(200, @files.present(version, download_uri)), { "version" => version.number } ]
        when "files.metadata"
          version = @files.metadata(state, target["path"], input)
          [ json(200, @files.present(version)), { "version" => version.number } ]
        when "transfers.download"
          version, response = @files.send_version(state, target, request.get_header("HTTP_RANGE"))
          [ response, { "bytes" => response.last.bytesize, "sha256" => version.sha256 } ]
        end
      end

      # The request values that fault rules for the operation may match on.
      def fault_match_values(state, operation, target, input)
        case operation
        when "users.create" then { "username" => input["username"] }
        when "transfers.upload_part" then { "path" => state.uploads[target["upload"]]&.path, "part" => target["part"] }
        when "transfers.download" then { "path" => @files.version_by_number(state, target["version"])&.path }
        else target.slice("id", "path")
        end
      end

      # API operations take query parameters merged with a JSON body. An upload part takes raw bytes,
      # counted against the transfer byte limit before they are read.
      def read_input(request, operation)
        case operation
        when "transfers.upload_part" then receive_part(request)
        when "transfers.download" then nil
        else request_params(request)
        end
      end

      def receive_part(request)
        size = request.content_length ? request.content_length.to_i : @limits.max_body_bytes
        raise body_too_large if size > @limits.max_body_bytes

        received = @lock.synchronize { @files.reserve(size) }
        begin
          received.bytes = (+read_body(request, size)).force_encoding(Encoding::BINARY).freeze
          received.sha256 = Digest::SHA256.hexdigest(received.bytes)
          received
        rescue StandardError
          @lock.synchronize { @files.release(received) }
          raise
        end
      end

      # The origin of upload and download URLs: FILES_MOCK_TRANSFER_ORIGIN when it is set, otherwise the
      # local address of the connection this request arrived on. The Host header never chooses it.
      def transfer_origin(request)
        return @transfer_origin if @transfer_origin

        socket = request.get_header("puma.socket")
        address = socket.local_address if socket.is_a?(BasicSocket)
        raise Error.not_supported("Set FILES_MOCK_TRANSFER_ORIGIN to the origin clients use to reach this server; this connection does not provide one") unless address&.ip?

        address = address.ipv6_to_ipv4 if address.ipv6_v4mapped?
        "http://#{address.ipv6? ? "[#{address.ip_address}]" : address.ip_address}:#{address.ip_port}"
      end

      def validated_origin(value)
        return if value.nil? || value.empty?

        uri = begin
          URI.parse(value)
        rescue URI::InvalidURIError
          nil
        end
        origin = uri && %w[http https].include?(uri.scheme) && uri.host.to_s != "" && uri.userinfo.nil? && [ "", "/" ].include?(uri.path) && uri.query.nil? && uri.fragment.nil?
        raise ArgumentError, "FILES_MOCK_TRANSFER_ORIGIN=#{value.inspect} must be an http or https origin without a path, such as http://127.0.0.1:40410" unless origin

        value.delete_suffix("/")
      end

      # Query parameters merged with a JSON object body, the way the Go and Python SDKs send them.
      def request_params(request)
        query = Rack::Utils.parse_nested_query(request.query_string)
        body = read_body(request)
        return query if body.empty?
        raise Error.not_supported("Simulation accepts only application/json request bodies") unless request.media_type == "application/json"

        query.merge(parse_json_object(body))
      rescue Rack::BadRequest
        raise Error.bad_request("The query string is invalid")
      rescue JSON::ParserError
        raise Error.invalid_body("The request body is not a valid JSON object")
      end

      def read_body(request, limit = @limits.max_body_bytes)
        raise body_too_large if request.content_length.to_i > limit

        body = request.body ? request.body.read(limit + 1).to_s : ""
        raise body_too_large if body.bytesize > limit

        body
      end

      def body_too_large
        Error.body_too_large(@limits.max_body_bytes)
      end

      def parse_json_object(body)
        value = JSON.parse(body)
        raise JSON::ParserError, "not an object" unless value.is_a?(Hash)

        value
      end

      def control(request)
        case "#{request.request_method} #{request.path_info.delete_prefix(CONTROL_PREFIX)}"
        when "GET /ready" then json(200, @lock.synchronize { readiness })
        when "POST /reset" then reset(control_body(request))
        when "GET /journal" then json(200, @lock.synchronize { { "epoch" => @state.epoch }.merge(@state.journal.as_json) })
        when "POST /faults" then add_fault(control_body(request))
        when "GET /faults" then json(200, @lock.synchronize { { "epoch" => @state.epoch }.merge(@state.faults.as_json) })
        else raise Error.new(404, "simulation/unknown-control", "Unknown Control", "There is no control endpoint #{request.request_method} #{printable(request.path_info)}")
        end
      rescue Error => e
        e.to_rack
      end

      # Control writes require a JSON content type, which a cross-site browser form cannot send without a CORS preflight.
      def control_body(request)
        raise Error.invalid_control("Control requests must be sent with Content-Type: application/json", status: 415) unless request.media_type == "application/json"

        body = read_body(request)
        body.empty? ? {} : parse_json_object(body)
      rescue JSON::ParserError
        raise Error.invalid_control("The request body must be a JSON object")
      end

      # Builds the replacement state completely before swapping it in, so an invalid or over-limit
      # fixture leaves the current state, journal and fault rules untouched.
      def reset(body)
        unknown = body.keys - [ "fixtures" ]
        raise Error.invalid_control("Unknown reset fields: #{unknown.join(", ")}") if unknown.any?

        fixtures = body.fetch("fixtures", {})
        raise Error.invalid_control("fixtures must be a JSON object") unless fixtures.is_a?(Hash)

        unknown = fixtures.keys - [ Users::RESOURCE ]
        raise Error.invalid_control("Only users fixtures are supported; unknown fixtures: #{unknown.join(", ")}") if unknown.any?

        users = fixtures.fetch(Users::RESOURCE, [])
        raise Error.invalid_control("fixtures.users must be an array of JSON objects") unless users.is_a?(Array) && users.all?(Hash)

        @lock.synchronize do
          state = State.new(@state.epoch + 1, @limits, FAULT_MATCH_KEYS)
          ids = users.each_with_index.map do |attributes, index|
            @users.create(state, attributes)["id"]
          rescue Error => e
            raise Error.new(e.status, e.type, e.title, "fixtures.users[#{index}]: #{e.message}")
          end
          @files.discard(@state)
          @state = state
          json(200, { "epoch" => state.epoch, "users" => ids })
        end
      end

      def add_fault(spec)
        json(201, @lock.synchronize { @state.faults.add(spec).as_json })
      end

      def readiness
        {
          "status" => "ready",
          "mode" => "simulation",
          "contract_version" => CONTRACT_VERSION,
          "simulator_version" => @version,
          "schema_sha256" => @schema_sha256,
          "instance" => @instance,
          "epoch" => @state.epoch,
          "operations" => OPERATIONS.map { |operation|
            { "id" => operation["id"], "method" => operation["method"], "path" => API_PREFIX + operation["path"], "swagger_operation_id" => @swagger_operation_ids.fetch(operation["id"]) }
          },
          "transfers" => { "operations" => TRANSFER_OPERATIONS.map { |operation| operation.slice("id", "method") }, "origin" => @transfer_origin }.merge(@files.readiness(@state)),
          "fixtures" => [ Users::RESOURCE ],
          "faults" => { "match" => FAULT_MATCH_KEYS, "statuses" => FaultRules::STATUSES, "max_attempt" => FaultRules::MAX_ATTEMPT,
                        "max_retry_after" => FaultRules::MAX_RETRY_AFTER, "max_rules" => FaultRules::MAX_RULES },
          "pagination" => { "order" => "id", "default_per_page" => Users::DEFAULT_PER_PAGE, "max_per_page" => Users::MAX_PER_PAGE,
                            "next_cursor_headers" => [ "X-Files-Cursor", "X-Files-Cursor-Next" ] },
          "limits" => @limits.to_h,
          "state" => { "users" => @state.users.size, "journal_entries" => @state.journal.size, "journal_complete" => @state.journal.complete?,
                       "pending_faults" => @state.faults.pending_count },
        }
      end

      def json(status, body, headers = {})
        [ status, { "content-type" => "application/json" }.merge(headers), [ JSON.generate(body) ] ]
      end

      def printable(text)
        text.dup.force_encoding(Encoding::UTF_8).scrub("?")
      end
    end
  end
end
