module FilesMockServer
  module Simulation
    # Faults added through the control API. A request's fault is decided before it is validated or
    # changes anything. There are two kinds of rule:
    #
    # - An explicit rule fails the Nth request (its `attempt`) that matches its operation and
    #   optional match values after the rule was added, once. It stays listed as pending until then,
    #   so an unused fault is visible rather than silently passing.
    # - A random rule ("random") decides every matching request from its seed, the request's values
    #   for the rule's key (such as path and part) and how many earlier matching requests had those
    #   values. Requests with other key values do not change a decision, so the same requests per key
    #   get the same decisions in any interleaving, and the schedule a rule lists can be replayed by
    #   adding the same rule after another reset or to another simulator.
    #
    # A random rule's selection (whether the hash of seed, key values and attempt falls under its
    # rate) is stable in any interleaving. What happens to a selected request is not: explicit rules
    # take precedence (the random rule records it as overridden), a connection fault the server cannot
    # make is unavailable, among random rules the first one added that selects a request fails it,
    # and once a rule has failed max_faults requests it records later selections as budget-exhausted.
    # max_faults is a budget for the whole rule, so which selected requests it fails follows arrival
    # order. Rules stay listed until the next reset.
    class FaultRules
      # Statuses a rule may answer with. Retryable ones name failures a client may send again (after
      # Retry-After when there is one); permanent ones name final answers. The simulator only labels them.
      RETRYABLE_STATUSES = [ 408, 429, 500, 502, 503, 504 ].freeze
      PERMANENT_STATUSES = [ 400, 401, 403, 404, 409, 412, 422, 423 ].freeze
      STATUSES = (PERMANENT_STATUSES + RETRYABLE_STATUSES).sort.freeze
      # What a rule does to the request it fails (README.md describes each). "error", the default,
      # answers with a Files.com API error body instead of applying the request.
      KINDS = %w[error unstructured redirect expired_url html_page empty_page delay hold drop_before drop_after truncate short_body excess_body stall].freeze
      # How an empty_page answer continues: "advance" gives a new cursor for the same position, so the
      # listing goes on; "repeat" gives back the cursor the request sent, so it makes no progress.
      EMPTY_PAGE_CURSORS = %w[advance repeat].freeze
      # Statuses a redirect rule may answer with; its Location is the rule's origin followed by the
      # request's own path and query.
      REDIRECT_STATUSES = [ 301, 302, 303, 307, 308 ].freeze
      # Kinds that answer with a chosen status instead of applying the request.
      STATUS_KINDS = %w[error unstructured].freeze
      # Kinds that close or cut the connection, which needs a server that supports Rack hijacking,
      # such as `bundle exec puma`.
      CONNECTION_KINDS = %w[drop_before drop_after truncate short_body excess_body stall].freeze
      # Kinds that cut, pad or pause a response body at "bytes".
      BODY_KINDS = %w[truncate short_body excess_body stall].freeze
      # Kinds that only make sense for some operations.
      OPERATION_KINDS = { "expired_url" => %w[transfers.upload_part transfers.download], "html_page" => %w[transfers.download] }.freeze
      MAX_RULES = 100
      MAX_ATTEMPT = 100
      MAX_RETRY_AFTER = 60
      MAX_DELAY_MS = 10_000
      # A hold keeps one request, before it is applied, for longer than a delay may: long enough to pass
      # a client's default read timeout (the SDKs' is 80 seconds). It is bounded by MAX_HOLD_MS, ends
      # early when a reset starts a new state or the client closes its connection (App#hold), and only
      # explicit rules hold. At most MAX_HOLDS hold rules are pending or holding a request at once: a
      # rule's place is taken when it is added and kept, once a request selects it, until that request
      # has been applied or refused (App#simulate), so held requests cannot occupy every server thread.
      MAX_HOLD_MS = 120_000
      MAX_HOLDS = 2
      MAX_BYTES = 16_777_216
      # Distinct key values and listed decisions one random rule keeps between resets.
      MAX_KEYS = 10_000
      MAX_SCHEDULE = 1_000
      # The largest "data" object an error rule may carry, as JSON text.
      MAX_DATA_BYTES = 4096
      FIELDS = %w[operation match attempt kind status retry_after type message data delay_ms when bytes location cursor random].freeze
      RANDOM_FIELDS = %w[seed rate key max_faults].freeze
      # Match values that name records or parts by number, and those that are true or false; the
      # others are strings.
      NUMBERED_MATCH_KEYS = %w[id part].freeze
      BOOLEAN_MATCH_KEYS = %w[continuation].freeze
      # A random rule's key may name the credential a request carries. The credential is never
      # stored or reported: schedules name it by its number in the journal (see App#credentials).
      SESSION = "session".freeze
      TYPE = /\A[a-z]+(?:-[a-z]+)*(?:\/[a-z]+(?:-[a-z]+)*)?\z/

      Rule = Struct.new(:id, :operation, :match, :attempt, :kind, :status, :retry_after, :type, :message, :delay_ms, :when, :bytes, :location, :cursor, :random,
                        :matched_requests, :consumed_by_request, :data
      ) do
        def pending?
          random.nil? && consumed_by_request.nil?
        end

        def connection?
          CONNECTION_KINDS.include?(kind)
        end

        # A delay before the request is applied, or a hold: it is held outside the simulator's lock, then applied.
        def hold_before?
          kind == "hold" || (kind == "delay" && self.when == "before")
        end

        def matches?(operation, values)
          self.operation == operation && match.all? { |key, expected| values[key] == expected }
        end

        # Both explicit rules could match the same request: no value they both constrain differs.
        def overlaps?(other)
          operation == other.operation && match.all? { |key, value| !other.match.key?(key) || other.match[key] == value }
        end

        def as_json
          fields = to_h.except(:random, :attempt, :matched_requests, :consumed_by_request).compact.transform_keys(&:to_s)
          return fields.merge("attempt" => attempt, "matched_requests" => matched_requests, "consumed_by_request" => consumed_by_request, "state" => pending? ? "pending" : "consumed") unless random

          fields.merge("random" => random.as_json, "state" => random.exhausted? ? "exhausted" : "active")
        end
      end

      # A random rule's configuration and what it has decided.
      class Chance
        # What a random rule did with a request it matched.
        OUTCOMES = %w[pass fault overridden unavailable budget-exhausted].freeze

        attr_reader :faulted

        def initialize(seed:, rate:, key:, max_faults:)
          @seed = seed
          @rate = rate
          @threshold = (rate.to_r * (2**64)).floor
          @key = key
          @max_faults = max_faults
          @attempts = {} # digest of key values => requests seen with them
          @schedule = []
          @unlisted = 0
          @faulted = 0
          @outcomes = Hash.new(0)
        end

        def exhausted?
          @faulted >= @max_faults
        end

        # Counts the request for its key values and returns [ selected, schedule entry ]: whether the
        # stable draw selects it, whatever then happens to it. `values` holds the request's match
        # values and its credential.
        def select(operation, values, reported)
          key_values = @key.to_h { |name| [ name, values[name] ] }
          counter = Digest::SHA256.hexdigest(JSON.generate(key_values))
          raise Error.limit_exceeded(409, "A random fault rule tracks at most #{MAX_KEYS} distinct key values between resets") if !@attempts.key?(counter) && @attempts.size >= MAX_KEYS

          attempt = @attempts[counter] = @attempts.fetch(counter, 0) + 1
          draw = Digest::SHA256.digest([ "files-mock-fault", @seed, operation, JSON.generate(key_values), attempt ].join("\0")).unpack1("Q>")
          selected = draw < @threshold
          [ selected, { "key" => @key.to_h { |name| [ name, reported[name] ] }, "attempt" => attempt, "selected" => selected } ]
        end

        def record(entry, outcome)
          @faulted += 1 if outcome == "fault"
          @outcomes[outcome] += 1
          @schedule.size < MAX_SCHEDULE ? @schedule << entry.merge("outcome" => outcome) : @unlisted += 1
        end

        def as_json
          { "seed" => @seed, "rate" => @rate, "key" => @key, "max_faults" => @max_faults, "faulted" => @faulted,
            "outcomes" => OUTCOMES.to_h { |outcome| [ outcome, @outcomes[outcome] ] }, "schedule" => @schedule.dup, "unlisted" => @unlisted }
        end
      end

      # The rule that fails a request, or one that would but cannot on this server (`available` false).
      Decision = Data.define(:rule, :available)

      # match_keys maps each operation ID to the request values its rules may match on: "id" (the
      # record ID in the path), "username", "path" (a file path), "continuation" (whether a list
      # request sends a cursor), a list of values a rule may combine, or nil when a rule matches every
      # request to it.
      def initialize(match_keys)
        @match_keys = match_keys
        @rules = []
      end

      # holding: the requests hold rules are holding now, in this state or one a reset replaced.
      def add(spec, holding: 0)
        rule = build(spec)
        raise Error.limit_exceeded(409, "At most #{MAX_RULES} fault rules can be added between resets") if @rules.size >= MAX_RULES

        pending_holds = @rules.count { |existing| existing.kind == "hold" && existing.pending? }
        raise Error.limit_exceeded(409, "At most #{MAX_HOLDS} hold rules can be pending or holding a request at once") if rule.kind == "hold" && pending_holds + holding >= MAX_HOLDS

        conflict = !rule.random && @rules.detect { |existing| existing.pending? && existing.overlaps?(rule) }
        raise Error.invalid_control("Fault rule #{conflict.id} is still pending for the same #{rule.operation} requests", status: 409) if conflict

        @rules << rule
        rule
      end

      # Decides whether a request, described by its match values, fails, and returns the Decision or
      # nil. Every matching random rule counts the request. `credential` is the credential the
      # request carries and `session` its number. `hijack` tells whether the server can close or cut
      # the connection; a rule that would need to is not consumed without it.
      def decide(operation, values, request_seq, credential: nil, session: nil, hijack: true)
        candidates = @rules.select { |rule| rule.matches?(operation, values) }
        chosen = nil
        explicit = candidates.detect(&:pending?)
        if explicit
          return Decision.new(explicit, false) if explicit.connection? && !hijack

          explicit.matched_requests += 1
          if explicit.matched_requests == explicit.attempt
            explicit.consumed_by_request = request_seq
            chosen = Decision.new(explicit, true)
          end
        end
        candidates.select(&:random).each do |rule|
          selected, entry = rule.random.select(operation, values.merge(SESSION => credential), values.merge(SESSION => session))
          outcome = if !selected then "pass"
                    elsif chosen then "overridden"
                    elsif rule.connection? && !hijack then "unavailable"
                    elsif rule.random.exhausted? then "budget-exhausted"
                    else
                      "fault"
                    end
          rule.random.record(entry.merge("seq" => request_seq), outcome)
          chosen = Decision.new(rule, outcome == "fault") if %w[fault unavailable].include?(outcome)
        end
        chosen
      end

      def pending_count
        @rules.count(&:pending?)
      end

      def as_json
        explicit = @rules.reject(&:random)
        { "faults" => @rules.map(&:as_json), "pending" => pending_count, "consumed" => explicit.size - pending_count, "random" => @rules.size - explicit.size }
      end

      private

      def build(spec)
        unknown = spec.keys - FIELDS
        raise Error.invalid_control("Unknown fault rule fields: #{unknown.join(", ")}") if unknown.any?

        operation = spec["operation"]
        raise Error.invalid_control("operation must be one of: #{@match_keys.keys.join(", ")}") unless @match_keys.key?(operation)

        kind = spec.fetch("kind", "error")
        raise Error.invalid_control("kind must be one of: #{KINDS.join(", ")}") unless KINDS.include?(kind)
        raise Error.invalid_control("#{kind} faults apply only to #{OPERATION_KINDS[kind].join(" and ")}") if OPERATION_KINDS.key?(kind) && !OPERATION_KINDS[kind].include?(operation)

        raise Error.invalid_control("empty_page faults apply only to list operations") if kind == "empty_page" && !Array(@match_keys[operation]).include?("continuation")

        check_fields(kind, spec)
        raise Error.invalid_control("hold rules are explicit; random does not apply to them") if kind == "hold" && spec.key?("random")

        random = chance(operation, spec["random"]) if spec.key?("random")
        raise Error.invalid_control("attempt applies only to rules without random") if random && spec.key?("attempt")

        attempt = spec.fetch("attempt", 1)
        raise Error.invalid_control("attempt must be a whole number from 1 to #{MAX_ATTEMPT}") unless attempt.is_a?(Integer) && attempt.between?(1, MAX_ATTEMPT)

        Rule.new(@rules.size + 1, operation, match_for(operation, spec.fetch("match", {})), (attempt unless random), kind, spec.fetch("status", (307 if kind == "redirect")),
                 spec["retry_after"], spec["type"], spec["message"], spec["delay_ms"], (spec.fetch("when", "before") if kind == "delay"), spec["bytes"], spec["location"],
                 (spec.fetch("cursor", "advance") if kind == "empty_page"), random, (0 unless random), nil, spec["data"]
        )
      end

      # Each field applies to some kinds only, and a field that does not apply is refused rather than ignored.
      def check_fields(kind, spec)
        if STATUS_KINDS.include?(kind)
          status = spec["status"]
          raise Error.invalid_control("status must be one of: #{STATUSES.join(", ")}") unless status.is_a?(Integer) && STATUSES.include?(status)
        end
        raise Error.invalid_control("cursor must be one of: #{EMPTY_PAGE_CURSORS.join(", ")}") unless spec["cursor"].nil? || EMPTY_PAGE_CURSORS.include?(spec["cursor"])

        if kind == "redirect"
          raise Error.invalid_control("status must be one of: #{REDIRECT_STATUSES.join(", ")}") unless spec["status"].nil? || REDIRECT_STATUSES.include?(spec["status"])
          raise Error.invalid_control("location must be an http or https origin without a path, such as http://127.0.0.1:4042") unless origin?(spec["location"])
        end
        retry_after = spec["retry_after"]
        raise Error.invalid_control("retry_after must be a whole number of seconds from 0 to #{MAX_RETRY_AFTER}") unless retry_after.nil? || (retry_after.is_a?(Integer) && retry_after.between?(0, MAX_RETRY_AFTER))
        raise Error.invalid_control("type must be a Files.com error type such as not-found or bad-request/invalid-cursor") unless spec["type"].nil? || (spec["type"].is_a?(String) && spec["type"].match?(TYPE))
        raise Error.invalid_control("message must be a string of 1 to 500 characters") unless spec["message"].nil? || (spec["message"].is_a?(String) && spec["message"].length.between?(1, 500))
        raise Error.invalid_control("data must be a JSON object of at most #{MAX_DATA_BYTES} bytes") unless spec["data"].nil? || (spec["data"].is_a?(Hash) && JSON.generate(spec["data"]).bytesize <= MAX_DATA_BYTES)

        if %w[delay stall hold].include?(kind)
          delay = spec["delay_ms"]
          most = kind == "hold" ? MAX_HOLD_MS : MAX_DELAY_MS
          raise Error.invalid_control("delay_ms must be a whole number of milliseconds from 1 to #{most}") unless delay.is_a?(Integer) && delay.between?(1, most)
        end
        raise Error.invalid_control("when must be before or after") unless spec["when"].nil? || %w[before after].include?(spec["when"])

        if BODY_KINDS.include?(kind)
          bytes = spec["bytes"]
          least = kind == "excess_body" ? 1 : 0
          raise Error.invalid_control("bytes must be a whole number from #{least} to #{MAX_BYTES}") unless bytes.is_a?(Integer) && bytes.between?(least, MAX_BYTES)
        end
        applies = { "status" => STATUS_KINDS + %w[redirect], "retry_after" => STATUS_KINDS, "type" => %w[error], "message" => %w[error], "data" => %w[error], "delay_ms" => %w[delay stall hold], "when" => %w[delay],
                    "bytes" => BODY_KINDS, "location" => %w[redirect], "cursor" => %w[empty_page] }
        misplaced = applies.reject { |field, kinds| !spec.key?(field) || kinds.include?(kind) }.keys
        raise Error.invalid_control("#{misplaced.join(", ")} do not apply to #{kind} faults") if misplaced.any?
      end

      def origin?(value)
        uri = URI.parse(value) if value.is_a?(String)
        uri.is_a?(URI::HTTP) && uri.host.to_s != "" && uri.userinfo.nil? && [ "", "/" ].include?(uri.path) && uri.query.nil? && uri.fragment.nil?
      rescue URI::InvalidURIError
        false
      end

      def chance(operation, spec)
        raise Error.invalid_control("random must be a JSON object") unless spec.is_a?(Hash)

        unknown = spec.keys - RANDOM_FIELDS
        raise Error.invalid_control("Unknown random fields: #{unknown.join(", ")}") if unknown.any?

        seed = spec["seed"]
        raise Error.invalid_control("random.seed must be a string of 1 to 100 characters") unless seed.is_a?(String) && seed.length.between?(1, 100)

        rate = spec["rate"]
        raise Error.invalid_control("random.rate must be a number greater than 0 and at most 1") unless rate.is_a?(Numeric) && rate.positive? && rate <= 1

        allowed = Array(@match_keys[operation]) + [ SESSION ]
        key = spec.fetch("key", [])
        raise Error.invalid_control("random.key must list distinct names from: #{allowed.join(", ")}") unless key.is_a?(Array) && key.uniq == key && (key - allowed).empty?

        max_faults = spec.fetch("max_faults", MAX_SCHEDULE)
        raise Error.invalid_control("random.max_faults must be a whole number from 1 to #{MAX_SCHEDULE}") unless max_faults.is_a?(Integer) && max_faults.between?(1, MAX_SCHEDULE)

        Chance.new(seed:, rate:, key:, max_faults:)
      end

      def match_for(operation, match)
        keys = Array(@match_keys[operation])
        raise Error.invalid_control("match must be a JSON object") unless match.is_a?(Hash)
        return match if match.empty?
        raise Error.invalid_control(keys.any? ? "#{operation} rules can only match on #{keys.join(" and ")}" : "#{operation} rules cannot use match") unless (match.keys - keys).empty?

        match.each do |key, value|
          if NUMBERED_MATCH_KEYS.include?(key)
            raise Error.invalid_control("match.#{key} must be a positive whole number") unless value.is_a?(Integer) && value.positive?
          elsif BOOLEAN_MATCH_KEYS.include?(key)
            raise Error.invalid_control("match.#{key} must be true or false") unless [ true, false ].include?(value)
          else
            raise Error.invalid_control("match.#{key} must be a string") unless value.is_a?(String)
          end
        end
        match
      end
    end
  end
end
