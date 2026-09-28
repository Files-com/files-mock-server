require "date"
require "digest"
require "json"
require "rack"
require "securerandom"

require_relative "simulation/error"
require_relative "simulation/limits"
require_relative "simulation/fault_rules"
require_relative "simulation/state"
require_relative "simulation/users"

module FilesMockServer
  # Opt-in (FILES_MOCK_MODE=simulation) stateful simulation of a small, advertised subset of the
  # Files.com REST API. Every other API request gets a 501 response, so a test cannot mistake an
  # unmodeled call for a pass. README.md documents the contract.
  module Simulation
    CONTRACT_VERSION = 1
    API_PREFIX = "/api/rest/v1".freeze
    CONTROL_PREFIX = "/__files_mock/v1".freeze
    # Simulated operations. "fault_match" names the request value a fault rule may match on.
    OPERATIONS = [
      { "id" => "users.create", "method" => "POST", "path" => "/users", "fault_match" => "username" },
      { "id" => "users.list", "method" => "GET", "path" => "/users", "fault_match" => nil },
      { "id" => "users.find", "method" => "GET", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.update", "method" => "PATCH", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.delete", "method" => "DELETE", "path" => "/users/{id}", "fault_match" => "id" }
    ].freeze
    FAULT_MATCH_KEYS = OPERATIONS.to_h { |operation| [ operation["id"], operation["fault_match"] ] }.freeze
    ROUTES = OPERATIONS.map { |operation|
      pattern = Regexp.escape(API_PREFIX + operation["path"]).sub("\\{id\\}", "([^/]+)")
      [ operation["method"], Regexp.new("\\A#{pattern}\\z"), operation["id"] ]
    }.freeze
    # Swagger-derived parameter and field metadata, generated beside this file.
    SCHEMA_PATH = File.expand_path("simulation/schema.json", __dir__)

    # One simulator. Its state belongs to this instance alone, and every access to it holds @lock.
    class App
      def initialize(limits: Limits.new, schema_path: SCHEMA_PATH)
        @limits = limits
        schema = JSON.parse(File.read(schema_path))
        require_complete(schema)
        @schema_sha256 = Digest::SHA256.file(schema_path).hexdigest
        @swagger_operation_ids = schema.fetch("operations").transform_values { |operation| operation.fetch("operation_id") }
        @version = File.read(File.expand_path("../_VERSION", __dir__)).strip
        @users = Users.new(schema, max_records: limits.max_records)
        @instance = SecureRandom.hex(6)
        @lock = Mutex.new
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
        missing << "the User entity" unless schema.fetch("entities").key?(Users::RESOURCE)
        return if missing.empty?

        raise ArgumentError, "Simulation mode needs #{missing.join(", ")}, which the Swagger document this server was generated from does not define. " \
                             "Regenerate the server from the Files.com API schema, or leave FILES_MOCK_MODE unset to use the legacy server."
      end

      def dispatch(request)
        if request.path_info.start_with?("#{CONTROL_PREFIX}/")
          control(request)
        elsif request.path_info.start_with?("#{API_PREFIX}/")
          api(request)
        else
          Error.not_found.to_rack
        end
      end

      # Parses outside the lock, then applies the reset-epoch check, fault matching, validation and the
      # state change as one atomic step under it. A parse failure is deferred into that step instead of
      # being returned early, so every API request, including a malformed one, gets a journal sequence
      # number. A request that entered the Rack application before a reset is refused rather than
      # applied to the new state.
      def api(request)
        arrival_epoch = @lock.synchronize { @state.epoch }
        operation, record_id = route(request)
        begin
          params = request_params(request) if operation
        rescue Error => e
          parse_error = e
        end

        @lock.synchronize do
          state = @state
          state.request_count += 1
          seq = state.request_count
          response, journaled_id = begin
            raise Error.stale_request unless state.epoch == arrival_epoch
            raise parse_error if parse_error
            raise Error.not_supported("#{request.request_method} #{printable(request.path_info)} is not simulated; GET #{CONTROL_PREFIX}/ready lists the supported operations") unless operation

            fault = state.faults.consume(operation, fault_match_value(operation, record_id, params), seq)
            raise Error.injected_fault(fault) if fault

            perform(state, operation, record_id, params)
          rescue Error => e
            [ e.to_rack, record_id ]
          end
          entry = { "seq" => seq, "epoch" => state.epoch, "method" => request.request_method, "path" => printable(request.path_info),
                    "operation" => operation, "id" => journaled_id, "fault_id" => fault&.id, "status" => response.first }
          state.journal.record(entry)
          response
        end
      end

      # Returns [ operation ID, record ID ]; the record ID is nil unless the path holds a positive integer.
      def route(request)
        ROUTES.each do |method, pattern, operation|
          next unless method == request.request_method && (match = pattern.match(request.path_info))

          return [ operation, match[1]&.match?(/\A[1-9][0-9]*\z/) ? Integer(match[1], 10) : nil ]
        end
        [ nil, nil ]
      end

      # Returns [ Rack response, record ID for the journal ]. The journal names the ID from the path,
      # except that a create names the ID it allocated.
      def perform(state, operation, record_id, params)
        case operation
        when "users.create"
          user = @users.create(state, params)
          [ json(201, user), user["id"] ]
        when "users.list"
          users, next_cursor = @users.list(state, params, @instance)
          [ json(200, users, next_cursor ? { "x-files-cursor" => next_cursor, "x-files-cursor-next" => next_cursor } : {}), record_id ]
        when "users.find"
          [ json(200, @users.find(state, record_id)), record_id ]
        when "users.update"
          [ json(200, @users.update(state, record_id, params)), record_id ]
        when "users.delete"
          @users.delete(state, record_id, params)
          [ [ 204, {}, [] ], record_id ]
        end
      end

      def fault_match_value(operation, record_id, params)
        case FAULT_MATCH_KEYS[operation]
        when "id" then record_id
        when "username" then params["username"]
        end
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

      def read_body(request)
        limit = @limits.max_body_bytes
        raise body_too_large if request.content_length.to_i > limit

        body = request.body ? request.body.read(limit + 1).to_s : ""
        raise body_too_large if body.bytesize > limit

        body
      end

      def body_too_large
        Error.limit_exceeded(413, "Request bodies are limited to #{@limits.max_body_bytes} bytes (FILES_MOCK_MAX_BODY_BYTES)")
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
