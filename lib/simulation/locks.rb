module FilesMockServer
  module Simulation
    # Advisory locks on paths (/locks/{path}): listed, created and released as the Files.com API's
    # lock controller and FileLock model do (read as source, not observed from a live site). A lock is
    # advisory: it never stops a file being written, moved or deleted, and it stays at its path when
    # the file moves or goes away. Clients check locks themselves.
    #
    # Only what the public API declares is simulated. The API creates a lock without a token only
    # when allow_access_by_any_user and exclusive are both true; the token, type and scope that would
    # allow anything else are internal parameters the public schema does not declare, so the model's
    # shared, owner-only defaults cannot be reached (the source's own mismatch, kept here, not
    # repaired). Every lock is therefore exclusive and releasable by any user of the site, and made by
    # no user (user_id -1): the simulator authenticates nobody.
    #
    # Locks are found as the model finds them (see #at and #range): by byte prefix in a sorted index,
    # not by folder. So a recursive lock's range takes in names that only start with its path ("a2"
    # for "a") and the path's own locks again, and a list with include_children shows those names too,
    # no deeper than one level below the path.
    #
    # Time is the lock clock: whole seconds from 0 at each reset, moved only by the control
    # POST /__files_mock/v1/locks/clock, so expiry is deterministic. A lock expires once its deadline
    # is before the clock; one whose deadline equals the clock is still live. An expired lock is no
    # longer listed, releasable or a sibling of a new lock, but it stays held, and still conflicts
    # through the model's ancestor and range queries, until POST /__files_mock/v1/locks/cleanup
    # removes it: those queries keep expired records until the model's removal job runs.
    #
    # Methods run under the App's lock.
    class Locks
      DEFAULT_TIMEOUT = 43_200 # 12 hours
      MAX_TIMEOUT = 604_800 # 1 week
      # The largest single advance of the lock clock.
      MAX_ADVANCE = (2**31) - 1
      REQUIRED_FLAGS = "token, allow_access_by_any_user, or exclusive".freeze
      # Parameters the lock controller takes that the public schema does not declare, by action. Each
      # changes what a request does (a token refreshes an existing lock, type, scope and depth stand in
      # for the booleans, owner is kept on the lock, a bundle code resolves a bundle's path), so they
      # are refused as not simulated rather than ignored.
      INTERNAL_PARAMS = { "create" => %w[token type scope depth owner bundle_registration_code], "list_for" => %w[bundle_registration_code],
                          "delete" => %w[bundle_registration_code] }.freeze
      # The user_id of a lock no user made, as with a site-wide API key.
      NO_USER = -1

      Lock = Data.define(:number, :path, :token, :recursive, :timeout, :created_at) do
        def deadline = created_at + timeout
        def expired?(clock) = deadline < clock
      end

      # operations: schema.json's locks.list_for, locks.create and locks.delete; fields: the Lock entity's.
      def initialize(operations, fields, namespace:, max_records:)
        # action => its declared parameters but the route's path, which a query or body copy never replaces
        @params = operations.to_h { |id, operation| [ id.delete_prefix("locks."), operation.fetch("params").except("path") ] }
        @fields = fields
        @namespace = namespace
        @max_records = max_records
      end

      # The controller's locks_for_path: the path's own live locks (with include_children, those in its
      # range no more than one level deeper), then each ancestor's live locks that apply to subfolders,
      # sorted by path. The answer is that whole array: cursor and per_page are checked as declared and
      # otherwise have no effect, as the action presents the array without paging it.
      def list(state, path, params)
        include_children = checked("list_for", params)["include_children"] == true
        path = checked_path(path)
        listed = from_path(state, path, include_children:) + ancestors(path).flat_map { |ancestor| from_path(state, ancestor).select(&:recursive) }
        listed.sort_by { |lock| [ lock.path, lock.number ] }.map { |lock| present(lock) }
      end

      # Returns [ the new lock as the API presents it, its number ]. Parameter types are checked first,
      # then the public requirement for both flags, then the path, then the locks it would conflict with.
      def create(state, path, params)
        values = checked("create", params)
        raise Error.request_params_required(REQUIRED_FLAGS) unless values["allow_access_by_any_user"] == true && values["exclusive"] == true

        path = checked_path(path)
        recursive = values["recursive"] != false
        conflicts = conflicting(state, path, recursive)
        raise Error.resource_locked(conflicts.map { |lock| "exclusive lock #{lock.token} at /#{lock.path}" }.join(", ")) if conflicts.any?
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} locks, expired ones included until a cleanup (FILES_MOCK_MAX_RECORDS)") if state.locks.size >= @max_records

        lock = Lock.new(number: state.last_lock_id += 1, path:, token: SecureRandom.uuid, recursive:, timeout: timeout(values["timeout"]), created_at: state.lock_clock)
        state.locks[lock.number] = lock
        [ present(lock), lock.number ]
      end

      # Releases the lock the model's get finds for this token at the path, and returns its number. Any
      # other token or path, a lock from before a reset, and an expired lock is not found. A token left
      # out fails the API's parameter validation (a bare bad-request with Grape's message); one sent
      # null or empty passes it and, like any other token, finds no lock.
      def delete(state, path, params)
        token = checked("delete", params)["token"]
        raise Error.bad_request("token is missing") unless params.key?("token")

        path = checked_path(path)
        lock = get(state, token, path) or raise Error.not_found
        state.locks.delete(lock.number).number
      end

      # POST /__files_mock/v1/locks/clock: { "advance_seconds": N } moves the lock clock forward.
      def advance(state, body)
        unknown = body.keys - [ "advance_seconds" ]
        raise Error.invalid_control("Unknown lock clock fields: #{unknown.join(", ")}") if unknown.any?

        seconds = body["advance_seconds"]
        raise Error.invalid_control("advance_seconds must be a whole number from 1 to #{MAX_ADVANCE}") unless seconds.is_a?(Integer) && seconds.between?(1, MAX_ADVANCE)

        state.lock_clock += seconds
        { "clock_seconds" => state.lock_clock }
      end

      # POST /__files_mock/v1/locks/cleanup (an empty JSON object) removes every expired lock, as the
      # API's removal job does when it runs; nothing else ever removes one before the next reset.
      def cleanup(state, body)
        raise Error.invalid_control("Lock cleanup takes no fields; got #{body.keys.join(", ")}") if body.any?

        expired = state.locks.values.select { |lock| lock.expired?(state.lock_clock) }
        expired.each { |lock| state.locks.delete(lock.number) }
        { "removed" => expired.size, "held" => state.locks.size }
      end

      def readiness(state)
        { "clock_seconds" => state.lock_clock, "held" => state.locks.size, "expired" => state.locks.each_value.count { |lock| lock.expired?(state.lock_clock) },
          "max_held" => @max_records, "default_timeout" => DEFAULT_TIMEOUT, "max_timeout" => MAX_TIMEOUT, "creatable" => { "allow_access_by_any_user" => true, "exclusive" => true } }
      end

      private

      # The model keeps every lock as a member "SITE:PATH:ID" of a sorted index and reads the index by
      # byte prefix (FileLock over RedisBacked). The locks at a path are the members starting with
      # "PATH:", so a lock at "a:b" is also at "a". Members come in index order: by path and, within a
      # path, here in creation order, since the model's IDs are not simulated.
      def at(state, path)
        indexed(state).select { |lock| "#{lock.path}:".start_with?("#{path}:") }
      end

      # The model's range from a path: every member starting with PATH, so the path's own locks, those
      # inside it at any depth, and those at names that only start with it ("a2" and "a2/x" for "a").
      def range(state, path)
        indexed(state).select { |lock| "#{lock.path}:".start_with?(path) }
      end

      def indexed(state)
        state.locks.values.sort_by { |lock| [ "#{lock.path}:", lock.number ] }
      end

      # The model's from_path: the live locks at the path, or with include_children those in its range
      # no more than one level deeper than the path.
      def from_path(state, path, include_children: false)
        found = include_children ? range(state, path) : at(state, path)
        found.select { |lock| depth(lock.path) <= depth(path) + 1 && !lock.expired?(state.lock_clock) }
      end

      # The model's get: of the locks at the path with this token, the one with the latest deadline,
      # unless it has expired.
      def get(state, token, path)
        lock = at(state, path).select { |held| held.token == token }.max_by(&:deadline)
        lock unless lock.nil? || lock.expired?(state.lock_clock)
      end

      # What a new exclusive lock conflicts with, in the order the model's validation compares them: its
      # siblings (the live locks at its path), every lock at its ancestors that applies to subfolders,
      # and, when it applies to its own subfolders, everything in its range. The ancestor and range
      # queries keep expired locks, and the range holds the path's own locks again, so a live lock at
      # the path is named twice.
      def conflicting(state, path, recursive)
        parents = ancestors(path).flat_map { |ancestor| at(state, ancestor) }.select(&:recursive)
        from_path(state, path) + parents + (recursive ? range(state, path) : [])
      end

      # The folders above a path, nearest first and the root ("") last, as the model walks up it.
      def ancestors(path)
        names = path.split("/")
        (names.size - 1).downto(0).map { |count| names.first(count).join("/") }
      end

      # The model's path_depth: how many names the path has.
      def depth(path)
        path.split("/").size
      end

      # A lock's path is kept as sent, in the form the API keeps paths in and under the API's rules for
      # a route's path (Namespace#request_path), and compared exactly; it is never checked against the
      # files and folders held.
      def checked_path(path)
        @namespace.request_path(path, route: :file)
      end

      # The declared parameters' values in their declared types; a value of the wrong type is refused
      # (422) before anything else is decided, and an internal parameter is refused as not simulated.
      def checked(action, params)
        internal = params.keys & INTERNAL_PARAMS.fetch(action)
        raise Error.not_supported("#{internal.join(", ")}: lock parameters the public API does not declare are not simulated") if internal.any?

        declared = @params.fetch(action)
        values = {}
        invalid = declared.filter_map do |name, rule|
          next if params[name].nil?

          value = Coercion.public_send(Coercion.for(rule), params[name])
          next name if value.equal?(Coercion::INVALID)

          values[name] = value
          nil
        end
        raise Error.bad_request(invalid.map { |name| "#{name} is invalid" }.join(", ")) if invalid.any?

        values
      end

      # The model's timeout: 12 hours when none, zero or a negative one is given, and at most a week.
      def timeout(seconds)
        return DEFAULT_TIMEOUT if seconds.nil? || seconds <= 0

        [ seconds, MAX_TIMEOUT ].min
      end

      # The lock as the API's Lock entity presents it. Owner and username are left out: owner is an
      # internal parameter, and a lock made by no user has no username.
      def present(lock)
        values = { "path" => lock.path, "timeout" => lock.timeout, "depth" => lock.recursive ? "infinity" : "0", "recursive" => lock.recursive, "scope" => "exclusive",
                   "exclusive" => true, "token" => lock.token, "type" => "office", "allow_access_by_any_user" => true, "user_id" => NO_USER }
        @fields.filter_map { |field| [ field, values[field] ] if values.key?(field) }.to_h
      end
    end
  end
end
