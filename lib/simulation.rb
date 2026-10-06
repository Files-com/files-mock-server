require "bigdecimal"
require "date"
require "digest"
require "erb"
require "json"
require "openssl"
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
require_relative "simulation/delivery"
require_relative "simulation/profile"
require_relative "simulation/state"
require_relative "simulation/records"
require_relative "simulation/users"
require_relative "simulation/namespace"
require_relative "simulation/zip_archive"
require_relative "simulation/locks"
require_relative "simulation/files"

module FilesMockServer
  # Opt-in (FILES_MOCK_MODE=simulation) stateful simulation of a small, advertised subset of the
  # Files.com REST API. Every other API request gets a 501 response, so a test cannot mistake an
  # unmodeled call for a pass. README.md documents the contract.
  module Simulation
    # 2: folders are records that can be created, listed and deleted, files can be deleted, and a
    # sequential upload of known size may be finalized without etags.
    # 3: every CRUDL resource with the regular collection/member shape is simulated as records,
    # the site as a singleton, and fixtures can fill any of them; files and folders can be copied,
    # moved and deleted recursively, with FileMigrations for copies and moves a profile makes pending;
    # fixtures can hold files and folders.
    CONTRACT_VERSION = 3
    API_PREFIX = "/api/rest/v1".freeze
    CONTROL_PREFIX = "/__files_mock/v1".freeze
    # How often a held request checks for a reset or its client closing (App#hold).
    HOLD_SLICE = 0.1
    # What the response half of a users.list journal entry's paging describes (App#paging).
    PAGING_BASIS = "selected-rack-response-before-delivery".freeze
    # Upload and download URLs that the file operations return. They are not Files.com API paths.
    TRANSFER_PREFIX = "/__files_mock/transfer".freeze
    # Operations with dedicated owners. "fault_match" names the request values a fault rule may match
    # on. Record resources generated into schema.json add their own operations (see App#record_operations).
    OPERATIONS = [
      { "id" => "users.create", "method" => "POST", "path" => "/users", "fault_match" => "username" },
      { "id" => "users.list", "method" => "GET", "path" => "/users", "fault_match" => "continuation" },
      { "id" => "users.find", "method" => "GET", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.update", "method" => "PATCH", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "users.delete", "method" => "DELETE", "path" => "/users/{id}", "fault_match" => "id" },
      { "id" => "files.begin_upload", "method" => "POST", "path" => "/file_actions/begin_upload/{path}", "fault_match" => "path" },
      { "id" => "files.finalize_upload", "method" => "POST", "path" => "/files/{path}", "fault_match" => "path" },
      { "id" => "files.download", "method" => "GET", "path" => "/files/{path}", "fault_match" => "path" },
      { "id" => "files.metadata", "method" => "GET", "path" => "/file_actions/metadata/{path}", "fault_match" => "path" },
      { "id" => "files.delete", "method" => "DELETE", "path" => "/files/{path}", "fault_match" => "path" },
      { "id" => "folders.create", "method" => "POST", "path" => "/folders/{path}", "fault_match" => "path" },
      { "id" => "folders.list", "method" => "GET", "path" => "/folders/{path}", "fault_match" => %w[path continuation] },
      { "id" => "files.copy", "method" => "POST", "path" => "/file_actions/copy/{path}", "fault_match" => "path" },
      { "id" => "files.move", "method" => "POST", "path" => "/file_actions/move/{path}", "fault_match" => "path" },
      { "id" => "file_migrations.find", "method" => "GET", "path" => "/file_migrations/{id}", "fault_match" => "id" },
      { "id" => "files.update", "method" => "PATCH", "path" => "/files/{path}", "fault_match" => "path" }
    ].freeze
    # Operations simulated when the Swagger document declares them, and left not simulated otherwise:
    # listing a ZIP file's entries, extracting them, and saving a ZIP of files and folders (Files::ZIP_OPERATIONS).
    ZIP_OPERATIONS = [
      { "id" => "files.zip_list", "method" => "GET", "path" => "/file_actions/zip_list/{path}", "fault_match" => "path" },
      { "id" => "files.unzip", "method" => "POST", "path" => "/file_actions/unzip", "fault_match" => "path" },
      { "id" => "files.zip", "method" => "POST", "path" => "/file_actions/zip", "fault_match" => "destination" }
    ].freeze
    # Advisory locks, simulated when the Swagger document declares all three operations and the Lock
    # entity (Locks), and left not simulated otherwise.
    LOCK_OPERATIONS = [
      { "id" => "locks.list_for", "method" => "GET", "path" => "/locks/{path}", "fault_match" => "path" },
      { "id" => "locks.create", "method" => "POST", "path" => "/locks/{path}", "fault_match" => "path" },
      { "id" => "locks.delete", "method" => "DELETE", "path" => "/locks/{path}", "fault_match" => "path" }
    ].freeze
    # What only a real Files.com site can answer. The simulator accepts any credential and reports
    # none of these, so evidence about them must come from a real site. Locks are simulated, but not
    # who may act on another user's lock (lock agency).
    REAL_ONLY = [ "authentication", "api key and site identity", "workspaces", "permissions", "lock agency", "behaviors", "creator ids" ].freeze
    # Byte transfers to the upload_uri and download_uri that the file operations return.
    TRANSFER_OPERATIONS = [
      { "id" => "transfers.upload_part", "method" => "PUT", "path" => "/upload/{ref}/{part}", "fault_match" => %w[path part] },
      { "id" => "transfers.download", "method" => "GET", "path" => "/download/{version}", "fault_match" => "path" }
    ].freeze
    # The status of a download request: its download URL joined with the X-Files-Download-Request-Id
    # the storage response gave (the Go SDK's url.JoinPath), the historical producer's
    # GET /download/:code/:request_id. Routed only while the reset's profile selects
    # download.request_status; otherwise the path is not simulated, as before.
    DOWNLOAD_STATUS_OPERATION = { "id" => "transfers.download_status", "method" => "GET", "path" => "/download/{version}/{request_id}", "fault_match" => "path" }.freeze
    # [ method, pattern, operation ID ] for each operation. A {path} placeholder takes the rest of the
    # request path, slashes included; the others take one segment.
    def self.routes(prefix, operations)
      operations.map do |operation|
        pattern = Regexp.escape(prefix + operation["path"]).gsub(/\\\{(\w+)\\\}/) { "(?<#{$1}>#{$1 == "path" ? ".+" : "[^/]+"})" }
        [ operation["method"], Regexp.new("\\A#{pattern}\\z"), operation["id"] ]
      end
    end
    ENTITIES = { Users::RESOURCE => "User", "files" => "File", "file_upload_parts" => "FileUploadPart", "file_actions" => "FileAction", "file_migrations" => "FileMigration" }.freeze
    # Reset fixtures the Files owner loads, after every record fixture.
    FILE_FIXTURES = %w[folders files].freeze
    # The reset fixture that holds fixture responses (FixtureResponses).
    RESPONSE_FIXTURES = "responses".freeze
    # Upload and copy/move destinations in another store, as the SDKs' destination helpers spell
    # them: _/RemoteServers/{id}/..., _/Snapshots/{id}/..., _/Sites/{id}/.... The simulator keeps
    # them in its own namespace like any path and journals the scope they name; it simulates no
    # remote server, snapshot or child site.
    EXTERNAL_DESTINATION = /\A_\/(RemoteServers|Snapshots|Sites)\/([1-9][0-9]*)(?:\/|\z)/
    EXTERNAL_KINDS = { "RemoteServers" => "remote_server", "Snapshots" => "snapshot", "Sites" => "child_site" }.freeze
    # Swagger-derived parameter and field metadata, generated beside this file.
    SCHEMA_PATH = File.expand_path("simulation/schema.json", __dir__)
    # Every operation in the Swagger document with how the simulator treats it, generated beside this file.
    INVENTORY_PATH = File.expand_path("simulation/inventory.json", __dir__)

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
        @file_action_fields = schema.fetch("entities").fetch("file_actions")
        @version = File.read(File.expand_path("../_VERSION", __dir__)).strip
        @transfer_origin = validated_origin(transfer_origin)
        @instance = SecureRandom.hex(6)
        @lock = Mutex.new
        @files = Files.new(schema, limits:, instance: @instance, lock: @lock)
        @owners = record_owners(schema, limits)
        @record_operations = record_operations
        # Member operations of records whose id is a string, which their route's {id} names (#route_target).
        @string_id_operations = @record_operations.filter_map { |id, (owner, action)| id if owner.is_a?(Records) && owner.public_id? && %w[find update delete].include?(action) }
        @scoped = scoped_lists(schema)
        @responses = schema.fetch("fixture_responses", {}).to_h { |id, definition| [ id, FixtureResponses.new(id, definition) ] }
        @locks = locks(schema, limits)
        # Specific routes come before the record routes they could be mistaken for (such as
        # /automations/authoring_schema and /automations/{id}). Users' operations are already in OPERATIONS.
        @operations = OPERATIONS + ZIP_OPERATIONS.select { |operation| schema.fetch("operations").key?(operation["id"]) } + (@locks ? LOCK_OPERATIONS : []) +
                      @responses.map { |id, responder| fixed_operation(id, responder.operation, nil) } +
                      @scoped.map { |id, (_, rule)| fixed_operation(id, rule, rule["path"].include?("{path}") ? %w[path continuation] : "continuation") } +
                      @record_operations.filter_map { |id, (owner, action)| record_operation(id, owner, action) unless owner.resource == Users::RESOURCE }
        @routes = Simulation.routes(API_PREFIX, @operations) + Simulation.routes(TRANSFER_PREFIX, TRANSFER_OPERATIONS + [ DOWNLOAD_STATUS_OPERATION ])
        @fault_match_keys = (@operations + TRANSFER_OPERATIONS + [ DOWNLOAD_STATUS_OPERATION ]).to_h { |operation| [ operation["id"], operation["fault_match"] ] }.freeze
        @state = State.new(0, limits, @fault_match_keys, @files.profile({}))
        # Requests a hold rule selected that have not yet been applied or refused, in any state: each
        # keeps its rule's place among FaultRules::MAX_HOLDS until then.
        @holding = 0
      end

      def call(env)
        request = Rack::Request.new(env)
        status, headers, body = dispatch(request)
        # Rack forbids a body in a HEAD response. HEAD is not simulated, so it keeps its error status.
        [ status, headers, request.head? ? [] : body ]
      end

      private

      # Users and the record resources, singletons and path records schema.json describes, by name.
      def record_owners(schema, limits)
        owners = { Users::RESOURCE => Users.build(schema, max_records: limits.max_records) }
        schema.fetch("resources", {}).each { |name, definition| owners[name] = Records.new(name, definition, max_records: limits.max_records) }
        schema.fetch("singletons", {}).each { |name, definition| owners[name] = Singleton.new(name, definition) }
        schema.fetch("path_resources", {}).each { |name, definition| owners[name] = PathRecords.new(name, definition, namespace: @files.namespace, max_records: limits.max_records) }
        clashes = owners.keys & (FILE_FIXTURES + [ RESPONSE_FIXTURES ])
        raise ArgumentError, "schema.json describes record resources named #{clashes.join(", ")}, which are reserved for file and response fixtures" if clashes.any?

        owners
      end

      # The lock owner, or nil when the Swagger document does not declare every lock operation and the Lock entity.
      def locks(schema, limits)
        ids = LOCK_OPERATIONS.map { |operation| operation["id"] }
        operations = schema.fetch("operations").slice(*ids)
        fields = schema.fetch("entities")["locks"]
        return unless operations.size == ids.size && fields

        Locks.new(operations, fields, namespace: @files.namespace, max_records: limits.max_records)
      end

      # Scoped list operation => [ its resource's owner, its rule ]. A rule scoped by a key only
      # fixtures set lets that resource's fixtures set it.
      def scoped_lists(schema)
        schema.fetch("scoped_lists", {}).filter_map do |id, rule|
          owner = @owners[rule.fetch("resource")] or next
          owner.allow_scope(rule["scope"]) if rule["scope"]
          [ id, [ owner, rule ] ]
        end.to_h
      end

      # The route of an operation at a fixed path (a scoped list or a fixture response).
      def fixed_operation(id, definition, fault_match)
        { "id" => id, "method" => "GET", "path" => definition.fetch("path"), "fault_match" => fault_match, "swagger_operation_id" => definition.fetch("operation_id") }
      end

      # Operation ID => [ owner, action ] for every record operation, users' included.
      def record_operations
        @owners.flat_map { |name, owner| owner.actions.map { |action| [ "#{name}.#{action}", [ owner, action ] ] } }.to_h
      end

      # The route, fault match and Swagger operation of a record operation. Member operations name a
      # record by the id in their path, which is also what their fault rules match on, except that a
      # record whose id is a string takes no match: a rule's match.id is a number.
      def record_operation(id, owner, action)
        member = owner.is_a?(Records) && %w[find update delete].include?(action)
        fault_match = if owner.is_a?(PathRecords)
                        "path"
                      else
                        { "list" => "continuation" }.fetch(action, member && !owner.public_id? ? "id" : nil)
                      end
        { "id" => id, "method" => owner.operations.fetch(action).fetch("method"), "path" => member ? "#{owner.path}/{id}" : owner.path,
          "fault_match" => fault_match, "swagger_operation_id" => owner.operations.fetch(action).fetch("operation_id") }
      end

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

      # Reads the request outside the lock, then applies the reset-epoch check, the fault decision,
      # validation and the state change as one atomic step under it. A read failure is deferred into
      # that step instead of being returned early, so every API and transfer request, including a
      # malformed one, gets a journal sequence number. A request that entered the Rack application
      # before a reset is refused rather than applied to the new state. A fault rule that delays a
      # request holds it between the decision and that step, outside the lock; one that changes how
      # the response is delivered does so after the step (Delivery).
      def simulate(request)
        arrived = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        arrival_epoch, request_status = @lock.synchronize { [ @state.epoch, @state.profile.download.request_status? ] }
        operation, target = route(request, arrival_epoch, request_status:)
        begin
          input = read_input(request, operation, target, arrival_epoch) if operation
        rescue Error => e
          read_error = e
        end

        exchange = [ request, operation, target, input, read_error, arrival_epoch, arrived ]
        response, fault, seq = step(*exchange)
        # step counted a hold it selected in @holding; it is released below however the request ends.
        holding = fault&.kind == "hold"
        if fault&.hold_before?
          held = hold(request, fault, arrival_epoch) if holding
          wait_before_applying(fault) unless held
          response, = step(*exchange, held: [ fault, seq, held ])
          fault = nil
        end
        fault && (fault.connection? || fault.kind == "delay") ? Delivery.deliver(request.env, fault, response) : response
      ensure
        @lock.synchronize do
          @holding -= 1 if holding
          @files.release(input) if input.is_a?(Files::Received)
        end
      end

      # One request's atomic step. Returns [ Rack response or nil, the rule to deliver it with or
      # nil, sequence number ]. held: [ rule, sequence number ] of a request a rule delayed before
      # this step, which is not decided again.
      def step(request, operation, target, input, read_error, arrival_epoch, arrived, held: nil)
        @lock.synchronize do
          state = @state
          fault, seq, hold_fields = held
          seq = state.request_count += 1 unless held && state.epoch == arrival_epoch
          response, outcome = begin
            raise Error.stale_request unless state.epoch == arrival_epoch

            # Numbering a new identity may be refused, before anything else happens.
            number_credentials(state, request)
            credential = credential(request)
            raise read_error if read_error
            raise Error.not_supported("#{request.request_method} #{printable(request.path_info)} is not simulated; GET #{CONTROL_PREFIX}/ready lists the supported operations") unless operation

            unless held
              decision = state.faults.decide(operation, fault_match_values(state, operation, target, input), seq,
                                             credential:, session: credential && state.credential_number(credential), hijack: request.get_header("rack.hijack?") == true
              )
              fault = decision&.rule
              raise Error.fault_unavailable(fault) if decision && !decision.available

              # The journal records the request once it is applied, after the delay. A selected hold
              # takes its place in @holding in this same step, so its rule's place is never free between.
              @holding += 1 if fault&.kind == "hold"
              return [ nil, fault, seq ] if fault&.hold_before?
              raise Error.injected_fault(fault) if fault&.kind == "error"
            end
            answered(fault, request, state, input) || perform(state, request, operation, target, resolved(state, input))
          rescue Error => e
            unavailable = decision && !decision.available ? { "fault_unavailable" => fault.id } : {}
            fault = nil if unavailable.any?
            [ e.to_rack, unavailable ]
          end
          # A successful storage download got its request ID when it was made (#perform); with
          # header_on_failure, any other storage download response gets one here.
          if operation == "transfers.download" && response && !response.first.between?(200, 299) && state.profile.download.header_on_failure?
            response, issued = @files.issue_download_request(state, target, response, nil)
            outcome = outcome.merge(issued)
          end
          entry = { "seq" => seq, "epoch" => state.epoch, "method" => request.request_method, "path" => printable(request.path_info),
                    "operation" => operation, "id" => target["id"], "fault_id" => fault&.id, "status" => response&.first }.merge(timing(state, arrived))
          entry["fault_kind"] = fault.kind if fault && fault.kind != "error"
          entry.update(Delivery.plan(fault, response)) if fault && response
          entry.update(hold_fields) if hold_fields
          if input.is_a?(Hash)
            entry["wire"] = wire_types(input)
            elements = wire_elements(input)
            entry["wire_elements"] = elements if elements.any?
          end
          scope = destination_scope(input["destination"]) || destination_scope(target["path"]) if input.is_a?(Hash) && operation.to_s.start_with?("files.", "folders.")
          entry["destination_scope"] = scope if scope
          observed = credentials(state, request)
          entry["credentials"] = observed if observed.any?
          entry["user_agent"] = printable(request.user_agent) if request.user_agent
          entry["paging"] = paging(input, response) if operation == "users.list"
          state.journal.record(entry.merge(target.slice("upload", "part", "version"), outcome))
          [ response, (fault if fault && (fault.connection? || fault.kind == "delay")), seq ]
        end
      end

      # Waits out a delay rule's delay_ms before its request is applied, outside the lock. A test can
      # replace it on its own app to decide when a delayed request goes on (transfer_profiles_test.rb).
      def wait_before_applying(fault)
        sleep(fault.delay_ms / 1000.0)
      end

      # Holds a request for its hold rule's delay_ms, outside the lock, a slice at a time. The hold
      # ends early when a reset starts a new state (the request is then refused as stale) or when the
      # client closes its connection or sends anything after its request, as a client that gave up
      # does; the request is then applied at once. Returns the journal's hold_ms, held_ms and
      # hold_ended ("elapsed", "reset" or "client-closed").
      def hold(request, fault, epoch)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        deadline = started + (fault.delay_ms / 1000.0)
        socket = request.get_header("puma.socket")
        io = socket.respond_to?(:to_io) ? socket.to_io : nil
        ended = loop do
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          break "elapsed" unless remaining.positive?
          break "reset" unless @lock.synchronize { @state.epoch } == epoch

          slice = [ remaining, HOLD_SLICE ].min
          if io.is_a?(BasicSocket)
            break "client-closed" if io.wait_readable(slice) && client_gone?(io)
          else
            sleep(slice)
          end
        end
        { "hold_ms" => fault.delay_ms, "held_ms" => ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round, "hold_ended" => ended }
      end

      # A readable connection whose request was already read has ended, or its client sent more.
      def client_gone?(io)
        io.recv_nonblock(1, Socket::MSG_PEEK, exception: false) != :wait_readable
      rescue IOError, SystemCallError
        true
      end

      # The response a rule sends instead of applying the request: an answer (Delivery.answer), no
      # response at all for drop_before, or nil when the request is applied.
      def answered(fault, request, state, input)
        return unless fault
        return [ nil, {} ] if fault.kind == "drop_before"
        return empty_page(state, fault, input) if fault.kind == "empty_page"

        answer = Delivery.answer(fault, request)
        [ answer, {} ] if answer
      end

      # When the request arrived and when its step finished, in milliseconds since the reset that made
      # the state, from a monotonic clock. Body bytes a response sends later are not included.
      def timing(state, arrived)
        { "arrived_ms" => [ ((arrived - state.started) * 1000).round, 0 ].max,
          "applied_ms" => ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - state.started) * 1000).round }
      end

      # An empty page for a list request, continuing with a cursor that stands for the same position
      # ("advance") or with the cursor the request sent ("repeat").
      def empty_page(state, fault, input)
        sent = input["cursor"].to_s
        cursor = if fault.cursor == "repeat" && !sent.empty?
                   sent
                 else
                   raise Error.limit_exceeded(409, "At most #{Namespace::MAX_CURSORS} empty_page cursors are issued between resets") if state.cursor_aliases.size >= Namespace::MAX_CURSORS

                   state.cursor_aliases << sent
                   state.profile.cursor(Token.encode("alias", @instance, state.epoch, state.cursor_aliases.size))
                 end
        [ json(200, [], { "x-files-cursor" => cursor, "x-files-cursor-next" => cursor }), cursor_digests(sent, cursor) ]
      end

      # A list request's input with an empty_page cursor replaced by the cursor it stands for.
      def resolved(state, input)
        return input unless input.is_a?(Hash) && input["cursor"].is_a?(String)

        values = Token.values(state.profile.token_of(input["cursor"]), "alias", @instance, state.epoch)
        number = Integer(values.first, 10) if values&.size == 1 && values.first.match?(/\A[1-9][0-9]*\z/)
        return input unless number && number <= state.cursor_aliases.size

        original = state.cursor_aliases[number - 1]
        original.empty? ? input.except("cursor") : input.merge("cursor" => original)
      end

      # Numbers each identity header the request carries (State#credential_number), or raises the
      # limit error for a new one past the limit.
      def number_credentials(state, request)
        %w[HTTP_X_FILESAPI_KEY HTTP_X_FILESAPI_AUTH].each { |name| state.credential_number(request.get_header(name)) if request.get_header(name) }
      end

      # The credential a request carries, which random fault rules may key on. It is never stored.
      def credential(request)
        request.get_header("HTTP_X_FILESAPI_KEY") || request.get_header("HTTP_X_FILESAPI_AUTH")
      end

      # Which identity headers a request carried, for the journal: an API key or session by its
      # number (State#credential_number), never its value, and the workspace ID as sent. The
      # simulator authenticates nothing; this only shows which credential a client sent where.
      def credentials(state, request)
        { "api_key" => request.get_header("HTTP_X_FILESAPI_KEY"), "session" => request.get_header("HTTP_X_FILESAPI_AUTH") }
          .compact.transform_values { |value| state.known_credential_number(value) || "unnumbered" }
          .merge("workspace_id" => request.get_header("HTTP_X_FILES_WORKSPACE_ID")).compact
      end

      # Returns [ operation ID, target ]. The target holds the route's values: a record ID or part number
      # (nil unless a positive integer; a string id is its segment decoded exactly once, nil unless
      # UTF-8), a file path decoded exactly once, and the upload or version number in a handle this
      # simulator issued in the epoch the request arrived in (else nil), with the download URL token
      # itself. The download status route counts only while the reset's profile selects request_status.
      def route(request, epoch, request_status: false)
        @routes.each do |method, pattern, operation|
          next unless method == request.request_method && (match = pattern.match(request.path_info))
          next if operation == DOWNLOAD_STATUS_OPERATION["id"] && !request_status

          return [ operation, route_target(match.named_captures, epoch, string_id: @string_id_operations.include?(operation)) ]
        end
        [ nil, {} ]
      end

      def route_target(captures, epoch, string_id: false)
        captures.each_with_object({}) do |(name, value), target|
          case name
          when "id" then target[name] = string_id ? decoded_id(value) : (Integer(value, 10) if value.match?(/\A[1-9][0-9]*\z/))
          when "part" then target[name] = value.match?(/\A[1-9][0-9]*\z/) ? Integer(value, 10) : nil
          when "ref" then target.update("ref" => value, "upload" => @files.upload_number(value, epoch))
          when "version" then target.update(@files.download_target(value, epoch)).update("download_token" => value)
          else target[name] = Rack::Utils.unescape_path(value).force_encoding(Encoding::UTF_8)
          end
        end
      end

      # A string id from its path segment, decoded once as the SDKs encode it; nil when it is not UTF-8.
      def decoded_id(segment)
        id = Rack::Utils.unescape_path(segment).force_encoding(Encoding::UTF_8)
        id if id.valid_encoding?
      end

      # Returns [ Rack response, journal fields ]. Every entry also records which identity headers the
      # request carried (#credentials) and its User-Agent. An entry names the record ID from the path, except
      # that a create names the ID it allocated. File and transfer entries name the upload, part and
      # version they used, with byte counts and SHA-256 digests, and whether a file or a folder was
      # found or deleted. A folder listing's entry has its item count and the SHA-256 of the cursor it
      # received and of the one it returned, so a traversal's cursors can be followed from page to
      # page. Entries never hold content, cursors themselves or credentials.
      def perform(state, request, operation, target, input)
        owner, action = @record_operations[operation]
        return perform_record(state, owner, action, target, input) if owner
        return perform_scoped(state, operation, target, input) if @scoped.key?(operation)
        return perform_response(state, operation, target, input) if @responses.key?(operation)

        case operation
        when "files.begin_upload"
          upload, parts = @files.begin_upload(state, target["path"], input, transfer_origin(request))
          [ json(200, parts), { "upload" => upload.id } ]
        when "transfers.upload_part"
          @files.check_signature(state, "PUT", request.path_info, request.query_string)
          part = @files.store_part(state, target, input)
          [ [ 200, { "etag" => %("#{part.etag}") }, [] ], { "bytes" => part.bytes.bytesize, "sha256" => part.etag } ]
        when "files.finalize_upload"
          status, upload, version = @files.finalize_upload(state, target["path"], input)
          [ json(status, @files.present(version, state:)), { "upload" => upload.id, "version" => version.number, "bytes" => version.size, "sha256" => version.sha256 } ]
        when "files.download"
          entry, download_uri, identity = @files.download(state, target["path"], input, transfer_origin(request))
          body = @files.present(entry, download_uri, state:)
          body["download_identity"] = identity if identity
          [ json(200, body), described(entry).merge(identity ? { "identity" => true } : {}) ]
        when "files.metadata"
          entry = @files.metadata(state, target["path"], input, accept_language: request.get_header("HTTP_ACCEPT_LANGUAGE"))
          [ json(200, @files.present(entry, state:)), described(entry) ]
        when "files.delete"
          entry, removed = @files.delete(state, target["path"], input)
          [ [ 204, {}, [] ], described(entry).merge(removed) ]
        when "files.update"
          entry = @files.update_file(state, target["path"], input)
          [ json(200, @files.present(entry, state:)), described(entry) ]
        when "files.copy", "files.move"
          action, fields = @files.public_send(operation.delete_prefix("files."), state, target["path"], input, state.profile)
          [ json(201, action.slice(*@file_action_fields)), fields ]
        when "files.zip_list"
          entries = @files.zip_list(state, target["path"], input)
          [ json(200, entries), { "entries" => entries.size } ]
        when "files.unzip", "files.zip"
          action, fields = @files.public_send(operation.delete_prefix("files."), state, input)
          [ json(201, action.slice(*@file_action_fields)), fields ]
        when "file_migrations.find"
          migration, fields = @files.migration(state, target["id"])
          [ json(200, migration), fields ]
        when "locks.list_for"
          locks = @locks.list(state, target["path"], input)
          [ json(200, locks), { "items" => locks.size } ]
        when "locks.create"
          lock, number = @locks.create(state, target["path"], input)
          [ json(201, lock), { "lock" => number } ]
        when "locks.delete"
          [ [ 204, {}, [] ], { "lock" => @locks.delete(state, target["path"], input) } ]
        when "folders.create"
          folder = @files.create_folder(state, target["path"], input)
          [ json(201, @files.present(folder, state:)), described(folder) ]
        when "folders.list"
          entries, next_cursor = @files.list_folder(state, target["path"], input)
          headers = next_cursor ? { "x-files-cursor" => next_cursor, "x-files-cursor-next" => next_cursor } : {}
          [ json(200, entries.map { |listed_entry| @files.present(listed_entry, state:) }, headers), { "items" => entries.size }.merge(cursor_digests(input["cursor"], next_cursor)) ]
        when "transfers.download"
          @files.check_signature(state, "GET", request.path_info, request.query_string)
          version, response = @files.send_version(state, target, request.get_header("HTTP_RANGE"), request.get_header("HTTP_IF_MATCH"))
          response, issued = @files.issue_download_request(state, target, response, response.last.bytesize)
          [ response, { "bytes" => response.last.bytesize, "sha256" => version.sha256 }.merge(issued) ]
        when "transfers.download_status"
          @files.download_request_status(state, target)
        end
      end

      # File parameters are checked and reported in the journal entry's "attachments" (see
      # Coercion::Attachment); no record stores their bytes.
      def perform_record(state, owner, action, target, input)
        status = owner.status(action)
        key = owner.is_a?(PathRecords) ? target["path"] : target["id"]
        attachments = []
        response, fields = case action
                           when "list"
                             if owner.lookup?
                               [ json(status, owner.find_by_fields(state, input)), {} ]
                             else
                               records, next_cursor = owner.list(state, input, @instance)
                               [ json(status, records, cursor_headers(next_cursor)), {} ]
                             end
                           when "create"
                             record = owner.create(state, input, attachments:)
                             [ json(status, record), { "id" => record["id"] }.compact ]
                           when "find" then [ json(status, owner.find(state, key)), {} ]
                           when "get" then [ json(status, owner.get(state)), {} ]
                           when "update" then [ json(status, owner.is_a?(Singleton) ? owner.update(state, input, attachments:) : owner.update(state, key, input, attachments:)), {} ]
                           when "delete"
                             owner.delete(state, key, input)
                             [ [ status, {}, [] ], {} ]
                           end
        [ response, attachments.empty? ? fields : fields.merge("attachments" => attachments.map(&:as_json)) ]
      end

      def perform_scoped(state, operation, target, input)
        owner, rule = @scoped.fetch(operation)
        records, next_cursor = owner.list_scoped(state, input, @instance, operation, rule, target[rule.fetch("from", "path")])
        [ json(200, records, cursor_headers(next_cursor)), { "items" => records.size } ]
      end

      # The route's values name the answer; a query or body copy of one of them never replaces it. A
      # lookup's answer is only that its key is known: 204 with no body (404 otherwise).
      def perform_response(state, operation, target, input)
        responder = @responses.fetch(operation)
        answer, next_cursor = responder.answer(state, input.merge(target), input, @instance)
        return [ [ 204, {}, [] ], {} ] if responder.lookup?

        [ json(200, answer, cursor_headers(next_cursor)), {} ]
      end

      def cursor_headers(cursor)
        cursor ? { "x-files-cursor" => cursor, "x-files-cursor-next" => cursor } : {}
      end

      # The external store an upload or copy/move destination names (EXTERNAL_DESTINATION), or nil.
      def destination_scope(path)
        match = EXTERNAL_DESTINATION.match(path.to_s) or return
        { "kind" => EXTERNAL_KINDS.fetch(match[1]), "id" => Integer(match[2], 10) }
      end

      # The JSON type of each request value, never the value: query values are always strings.
      def wire_types(input)
        input.transform_values { |value| wire_type(value) }
      end

      # For each top-level array value, how many elements it has and the distinct JSON types they
      # arrived as, before any coercion (a decimal array sent as strings is ["string"], as numbers
      # ["number"]): at most seven type names whatever the array's size, and never an element's value.
      def wire_elements(input)
        input.select { |_, value| value.is_a?(Array) }.transform_values { |value| { "count" => value.size, "types" => value.map { |item| wire_type(item) }.uniq.sort } }
      end

      def wire_type(value)
        case value
        when nil then "null"
        when true, false then "boolean"
        when Numeric then "number"
        when String then "string"
        when Array then "array"
        else value.is_a?(Hash) && value.key?(:multipart) ? "file" : "object"
        end
      end

      def described(entry)
        entry.is_a?(Namespace::Folder) ? { "type" => "directory" } : { "type" => "file", "version" => entry.number }
      end

      def cursor_digests(received, issued)
        { "cursor_sha256" => (Digest::SHA256.hexdigest(received) if received.is_a?(String) && !received.empty?),
          "next_cursor_sha256" => (Digest::SHA256.hexdigest(issued) if issued) }.compact
      end

      # A users.list entry's paging: the per_page and cursor the request's parsed parameters held as
      # it sent them, before an empty_page cursor was resolved or any value was checked, and the
      # X-Files-Cursor and X-Files-Cursor-Next headers of the response this step selected (the page,
      # an error, or a fault's answer or empty page), each read on its own. "available" is false when
      # the request could not be read, or when no response was selected (drop_before). Values are
      # described by #paging_value, never stored. This is the response the simulator selected, not
      # what a client received: Delivery may still delay, cut short or drop it.
      def paging(input, response)
        params = input.is_a?(Hash) ? input : {}
        headers = response ? response[1] : {}
        per_page = params["per_page"]
        # Coercion.int32 cannot match a string whose bytes are not valid UTF-8; such a value is no integer.
        integer = Coercion.int32(per_page) unless per_page.is_a?(String) && !per_page.valid_encoding?
        {
          "request" => { "available" => input.is_a?(Hash), "per_page" => paging_value(params, "per_page").merge("integer" => (integer if integer.is_a?(Integer))),
                         "cursor" => paging_cursor(params, "cursor") },
          "response" => { "available" => !response.nil?, "basis" => PAGING_BASIS, "cursor" => paging_cursor(headers, "x-files-cursor"),
                          "cursor_next" => paging_cursor(headers, "x-files-cursor-next") },
        }
      end

      # Whether `values` has the key `name` (whatever its value), the value's JSON type (#wire_type)
      # when it does, and the SHA-256 of its bytes when it is a string, the empty string included.
      def paging_value(values, name)
        present = values.key?(name)
        value = values[name]
        { "present" => present, "wire_type" => (wire_type(value) if present), "sha256" => (Digest::SHA256.hexdigest(value) if value.is_a?(String)) }
      end

      # A cursor's #paging_value, and whether it is a string that is not empty.
      def paging_cursor(values, name)
        value = values[name]
        paging_value(values, name).merge("nonempty" => value.is_a?(String) && !value.empty?)
      end

      # The request values that fault rules for the operation may match on.
      def fault_match_values(state, operation, target, input)
        case operation
        when "users.create" then { "username" => input["username"] }
        when "transfers.upload_part" then { "path" => state.uploads[target["upload"]]&.path, "part" => target["part"] }
        when "transfers.download", "transfers.download_status" then { "path" => @files.version_by_number(state, target["version"])&.path }
        # Unzip names its ZIP file in its parameters, not its URL.
        when "files.unzip" then { "path" => (input["path"] if input.is_a?(Hash)) }
        # A ZIP names the file it saves in its parameters; its selected paths are a list.
        when "files.zip" then { "destination" => (input["destination"] if input.is_a?(Hash)) }
        else
          values = target.slice("id", "path")
          values["continuation"] = !input["cursor"].to_s.empty? if Array(@fault_match_keys[operation]).include?("continuation") && input.is_a?(Hash)
          values
        end
      end

      # API operations take query parameters merged with a JSON body. An upload part takes raw bytes,
      # counted against the transfer byte limit before they are read.
      def read_input(request, operation, target, epoch)
        case operation
        when "transfers.upload_part" then receive_part(request, target, epoch)
        when "transfers.download", "transfers.download_status" then nil
        else request_params(request)
        end
      end

      # Admits the part (Files#admit) under the lock, then reads it outside the lock. The route's
      # upload number belongs to the epoch the request arrived in.
      def receive_part(request, target, epoch)
        size = request.content_length ? request.content_length.to_i : @limits.max_body_bytes
        raise body_too_large if size > @limits.max_body_bytes

        offset = part_offset(request)
        received = @lock.synchronize do
          # A new identity past the limit is refused before admission counts a send, an offset or a
          # length for the part; #step numbers the same identity again and refuses the request.
          number_credentials(@state, request) if @state.epoch == epoch
          @files.admit(@state, (target if @state.epoch == epoch), size, offset, declared: (size if request.content_length))
        end
        begin
          received.bytes = (+read_body(request, size)).force_encoding(Encoding::BINARY).freeze
          received.sha256 = Digest::SHA256.hexdigest(received.bytes)
          @lock.synchronize { @files.bind_length(@state, received) if @state.epoch == epoch }
          received
        rescue StandardError
          @lock.synchronize { @files.release(received) }
          raise
        end
      end

      # The part_offset query value an upload URL was sent with, or nil.
      def part_offset(request)
        value = Rack::Utils.parse_query(request.query_string)["part_offset"]
        return if value.nil?
        raise Error.bad_request("part_offset is invalid") unless value.is_a?(String) && value.match?(/\A(?:0|[1-9][0-9]*)\z/)

        Integer(value, 10)
      rescue Rack::BadRequest
        raise Error.bad_request("The query string is invalid")
      end

      # The origin of upload and download URLs: FILES_MOCK_TRANSFER_ORIGIN when it is set, otherwise the
      # scheme and local address of the connection this request arrived on (https behind a TLS bind).
      # The Host header never chooses it.
      def transfer_origin(request)
        return @transfer_origin if @transfer_origin

        socket = request.get_header("puma.socket")
        # A TLS connection's socket wraps the TCP socket it arrived on.
        socket = socket.to_io if !socket.is_a?(BasicSocket) && socket.respond_to?(:to_io)
        address = socket.local_address if socket.is_a?(BasicSocket)
        raise Error.not_supported("Set FILES_MOCK_TRANSFER_ORIGIN to the origin clients use to reach this server; this connection does not provide one") unless address&.ip?

        address = address.ipv6_to_ipv4 if address.ipv6_v4mapped?
        "#{request.scheme == "https" ? "https" : "http"}://#{address.ipv6? ? "[#{address.ip_address}]" : address.ip_address}:#{address.ip_port}"
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

      # Query parameters merged with the body's, the body's winning, the way the Go and Python SDKs
      # send a JSON object body and the Ruby SDK a form body.
      def request_params(request)
        query = begin
          Rack::Utils.parse_nested_query(request.query_string)
        rescue Rack::BadRequest
          raise Error.bad_request("The query string is invalid")
        end
        body = read_body(request)
        return query if body.empty?

        query.merge(body_params(request, body))
      end

      # A request body's parameters. A form body is read within FILES_MOCK_MAX_BODY_BYTES and then
      # parsed by Rack's own form parser, within its nesting depth and parameter count limits, into the
      # same strings, arrays and hashes a query string gives.
      def body_params(request, body)
        case request.media_type
        when "application/json" then parse_json_object(body, decimal_class: BigDecimal)
        when "application/x-www-form-urlencoded" then Rack::Utils.parse_nested_query(body)
        when "multipart/form-data" then multipart_params(request, body)
        else raise Error.not_supported("Simulation accepts only application/json, application/x-www-form-urlencoded and multipart/form-data request bodies")
        end
      rescue Rack::Multipart::Error, EOFError
        raise Error.invalid_body("The request body is not valid multipart/form-data")
      rescue Rack::BadRequest
        raise Error.invalid_body("The request body is not valid #{request.media_type}")
      rescue JSON::ParserError
        raise Error.invalid_body("The request body is not a valid JSON object")
      end

      # A multipart/form-data body, parsed by Rack as the Files.com API parses it and held in memory
      # (within FILES_MOCK_MAX_BODY_BYTES). Fields are strings, as multipart carries them; each file
      # part becomes { multipart:, filename:, raw_filename:, type:, bytes: }, raw_filename being the
      # part's Content-Disposition filename exactly as sent.
      def multipart_params(request, body)
        env = { "CONTENT_TYPE" => request.content_type, "CONTENT_LENGTH" => body.bytesize.to_s, "rack.input" => StringIO.new(body),
                Rack::RACK_MULTIPART_TEMPFILE_FACTORY => ->(_filename, _content_type) { StringIO.new(+"".b) } }
        uploaded(Rack::Multipart.parse_multipart(env) || {})
      end

      def uploaded(value)
        case value
        when Hash
          next_value = value.key?(:tempfile) ? nil : value.transform_values { |item| uploaded(item) }
          next_value || { multipart: true, filename: value[:filename], raw_filename: value[:head].to_s[/filename="((?:\\.|[^"\\])*)"/, 1], type: value[:type],
                          bytes: value[:tempfile].tap(&:rewind).read.b }
        when Array then value.map { |item| uploaded(item) }
        else value
        end
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

      def parse_json_object(body, **)
        value = JSON.parse(body, **)
        raise JSON::ParserError, "not an object" unless value.is_a?(Hash)

        value
      end

      def control(request)
        case "#{request.request_method} #{request.path_info.delete_prefix(CONTROL_PREFIX)}"
        when "GET /ready" then json(200, @lock.synchronize { readiness })
        when "POST /reset" then reset(control_body(request))
        when "GET /journal" then json(200, @lock.synchronize { { "epoch" => @state.epoch }.merge(@state.journal.as_json, "upload_parts" => upload_parts) })
        when "POST /faults" then add_fault(control_body(request))
        when "GET /faults" then json(200, @lock.synchronize { { "epoch" => @state.epoch }.merge(@state.faults.as_json, "holding" => @holding) })
        when "GET /inventory" then inventory
        when "POST /locks/clock" then lock_control(control_body(request)) { |state, body| @locks.advance(state, body) }
        when "POST /locks/cleanup" then lock_control(control_body(request)) { |state, body| @locks.cleanup(state, body) }
        else raise Error.new(404, "simulation/unknown-control", "Unknown Control", "There is no control endpoint #{request.request_method} #{printable(request.path_info)}")
        end
      rescue Error => e
        e.to_rack
      end

      # The upload parts holding a place now and the most that held one at once since the reset, as
      # admission counted them under the lock (Files#admit and #release).
      def upload_parts
        { "in_flight" => @files.parts_in_flight(@state), "most_in_flight" => @state.most_parts_in_flight }
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
      # fixture leaves the current state, journal and fault rules untouched. Fixtures name any record
      # resource (an array of records) or singleton (one object), and "folders" and "files" (see
      # Files#load_fixtures), which load last; readiness lists them. "profile" chooses the new state's
      # Profile.
      def reset(body)
        unknown = body.keys - %w[fixtures profile]
        raise Error.invalid_control("Unknown reset fields: #{unknown.join(", ")}") if unknown.any?

        profile = @files.profile(body.fetch("profile", {}))
        fixtures = body.fetch("fixtures", {})
        raise Error.invalid_control("fixtures must be a JSON object") unless fixtures.is_a?(Hash)

        unknown = fixtures.keys - @owners.keys - FILE_FIXTURES - [ RESPONSE_FIXTURES ]
        raise Error.invalid_control("Unknown fixtures: #{unknown.join(", ")}; GET #{CONTROL_PREFIX}/ready lists the resources fixtures can fill") if unknown.any?

        @lock.synchronize do
          state = State.new(@state.epoch + 1, @limits, @fault_match_keys, profile)
          loaded = fixtures.except(*FILE_FIXTURES, RESPONSE_FIXTURES).to_h { |name, value| [ name, load_fixtures(state, name, value) ] }
          loaded[RESPONSE_FIXTURES] = load_responses(state, fixtures[RESPONSE_FIXTURES]) if fixtures.key?(RESPONSE_FIXTURES)
          # Files load last: their bytes are counted only once nothing else can refuse the reset.
          loaded.update(@files.load_fixtures(state, fixtures.fetch("folders", []), fixtures.fetch("files", []), replacing: @state).slice(*fixtures.keys))
          @files.discard(@state)
          @state = state
          json(200, { "epoch" => state.epoch }.merge(loaded))
        end
      end

      # Returns the ids a resource's fixtures got (their number, for a resource without ids), or true for a singleton.
      def load_fixtures(state, name, value)
        owner = @owners.fetch(name)
        if owner.is_a?(Singleton)
          raise Error.invalid_control("fixtures.#{name} must be a JSON object") unless value.is_a?(Hash)

          fixture_error(name) { owner.load(state, value) }
          return true
        end
        raise Error.invalid_control("fixtures.#{name} must be an array of JSON objects") unless value.is_a?(Array) && value.all?(Hash)

        records = value.each_with_index.map { |attributes, index| fixture_error("#{name}[#{index}]") { owner.load(state, attributes) } }
        records.all? { |record| record.key?("id") } ? records.map { |record| record["id"] } : records.size
      end

      # fixtures.responses: fixture response operation => answer (see FixtureResponses).
      def load_responses(state, responses)
        raise Error.invalid_control("fixtures.#{RESPONSE_FIXTURES} must be a JSON object") unless responses.is_a?(Hash)

        unknown = responses.keys - @responses.keys
        raise Error.invalid_control("Unknown fixture responses: #{unknown.join(", ")}; GET #{CONTROL_PREFIX}/ready lists them") if unknown.any?

        responses.to_h { |id, value| [ id, fixture_error("#{RESPONSE_FIXTURES}.#{id}") { @responses.fetch(id).load(state, value) } ] }
      end

      def fixture_error(label)
        yield
      rescue Error => e
        raise Error.new(e.status, e.type, e.title, "fixtures.#{label}: #{e.message}")
      end

      # A lock clock or cleanup control, given its already-read body and answered with the epoch it
      # applied to. A server whose schema declares no locks has neither.
      def lock_control(body = nil)
        raise Error.new(404, "simulation/unknown-control", "Unknown Control", "This server simulates no locks: its Swagger document does not declare them") unless @locks

        json(200, @lock.synchronize { { "epoch" => @state.epoch }.merge(yield(@state, body)) })
      end

      # The generated operation inventory, as generated. A server without one says so.
      def inventory
        raise Error.new(404, "simulation/no-inventory", "No Inventory", "This server was generated without lib/simulation/inventory.json") unless File.file?(INVENTORY_PATH)

        [ 200, { "content-type" => "application/json" }, [ File.read(INVENTORY_PATH) ] ]
      end

      def add_fault(spec)
        json(201, @lock.synchronize { @state.faults.add(spec, holding: @holding).as_json })
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
          "operations" => @operations.map { |operation|
            { "id" => operation["id"], "method" => operation["method"], "path" => API_PREFIX + operation["path"],
              "swagger_operation_id" => operation["swagger_operation_id"] || @swagger_operation_ids.fetch(operation["id"]) }
          },
          "records" => { "resources" => @owners.count { |_, owner| owner.is_a?(Records) }, "singletons" => @owners.count { |_, owner| owner.is_a?(Singleton) },
                         "unset_fields" => "omitted", "write_only" => Records::WRITE_ONLY.source, "filtering_and_sorting" => false, "uniqueness" => false,
                         "foreign_keys" => false },
          "transfers" => { "operations" => TRANSFER_OPERATIONS.map { |operation| operation.slice("id", "method") }, "origin" => @transfer_origin }.merge(@files.readiness(@state)),
          "namespace" => @files.namespace.readiness(@state),
          "locks" => @locks&.readiness(@state),
          "real_only" => REAL_ONLY,
          "fixtures" => @owners.keys + FILE_FIXTURES + [ RESPONSE_FIXTURES ],
          "fixture_responses" => @responses.keys,
          "scoped_lists" => @scoped.transform_values { |_, rule| rule.slice("resource", "field", "scope", "values", "ancestors").compact },
          "profile" => @state.profile.as_json,
          "profile_basis" => Profile::BASIS,
          "profile_choices" => { "file_actions" => Profile::FILE_ACTIONS, "list_cursors" => Profile::LIST_CURSORS,
                                 "upload" => { "mode" => Profile::Upload::MODES, "upload_target_class" => Profile::Upload::TARGET_CLASSES },
                                 "download" => { "identity" => Profile::Download::IDENTITIES, "request_status" => { "status" => Profile::Download::REQUEST_STATUSES, "header_on_failure" => [ false, true ] },
                                                 "size" => Profile::Download::SIZES },
                                 "site_policy" => { "always_mkdir_parents" => [ true, false ] } },
          "faults" => { "match" => @fault_match_keys, "statuses" => FaultRules::STATUSES, "retryable_statuses" => FaultRules::RETRYABLE_STATUSES,
                        "permanent_statuses" => FaultRules::PERMANENT_STATUSES, "kinds" => FaultRules::KINDS, "connection_kinds" => FaultRules::CONNECTION_KINDS,
                        "random" => { "session_key" => FaultRules::SESSION, "max_keys" => FaultRules::MAX_KEYS, "max_schedule" => FaultRules::MAX_SCHEDULE },
                        "max_attempt" => FaultRules::MAX_ATTEMPT, "max_retry_after" => FaultRules::MAX_RETRY_AFTER, "max_delay_ms" => FaultRules::MAX_DELAY_MS,
                        "max_hold_ms" => FaultRules::MAX_HOLD_MS, "max_holds" => FaultRules::MAX_HOLDS, "max_rules" => FaultRules::MAX_RULES },
          "pagination" => { "order" => "id", "default_per_page" => Records::DEFAULT_PER_PAGE, "max_per_page" => Records::MAX_PER_PAGE,
                            "next_cursor_headers" => [ "X-Files-Cursor", "X-Files-Cursor-Next" ] },
          "limits" => @limits.to_h,
          "identities" => { "numbered" => @state.credential_count, "max" => State::MAX_CREDENTIALS },
          "state" => { "users" => @state.users.size, "records" => @state.records.sum { |_, records| records.size }, "singletons" => @state.singletons.size,
                       "path_records" => @state.path_records.sum { |_, records| records.size }, "responses" => @state.responses.size,
                       "file_migrations" => @state.migrations.size,
                       "journal_entries" => @state.journal.size, "journal_complete" => @state.journal.complete?,
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
