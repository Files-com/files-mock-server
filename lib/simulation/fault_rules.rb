module FilesMockServer
  module Simulation
    # One-shot HTTP faults added through the control API. A rule fails the Nth request (its
    # `attempt`) that matches its operation and optional match values after the rule was added,
    # before that request is validated or changes anything. Rules stay listed as pending or
    # consumed until the next reset, so an unused fault is visible rather than silently passing.
    class FaultRules
      STATUSES = [ 429, 500, 502, 503, 504 ].freeze
      MAX_RULES = 100
      MAX_ATTEMPT = 100
      MAX_RETRY_AFTER = 60
      FIELDS = %w[operation match attempt status retry_after].freeze
      # Match values that name records or parts by number; the others are strings.
      NUMBERED_MATCH_KEYS = %w[id part].freeze

      Rule = Struct.new(:id, :operation, :match, :attempt, :status, :retry_after, :matched_requests, :consumed_by_request) do
        def pending?
          consumed_by_request.nil?
        end

        # Both rules could match the same request: no value they both constrain differs.
        def overlaps?(other)
          operation == other.operation && match.all? { |key, value| !other.match.key?(key) || other.match[key] == value }
        end

        def as_json
          to_h.transform_keys(&:to_s).merge("state" => pending? ? "pending" : "consumed")
        end
      end

      # match_keys maps each operation ID to the request value its rules may match on: "id" (the
      # record ID in the path), "username", "path" (a file path), a list of values a rule may combine
      # (["path", "part"] for upload parts), or nil when a rule matches every request to it.
      def initialize(match_keys)
        @match_keys = match_keys
        @rules = []
      end

      def add(spec)
        rule = build(spec)
        raise Error.limit_exceeded(409, "At most #{MAX_RULES} fault rules can be added between resets") if @rules.size >= MAX_RULES

        conflict = @rules.detect { |existing| existing.pending? && existing.overlaps?(rule) }
        raise Error.invalid_control("Fault rule #{conflict.id} is still pending for the same #{rule.operation} requests", status: 409) if conflict

        @rules << rule
        rule
      end

      # Counts a request, described by its match values, against the pending rule it matches; returns
      # that rule if this request is the one it fails.
      def consume(operation, values, request_seq)
        rule = @rules.detect { |candidate|
          candidate.pending? && candidate.operation == operation && candidate.match.all? { |key, expected| values[key] == expected }
        }
        return unless rule

        rule.matched_requests += 1
        return unless rule.matched_requests == rule.attempt

        rule.consumed_by_request = request_seq
        rule
      end

      def pending_count
        @rules.count(&:pending?)
      end

      def as_json
        { "faults" => @rules.map(&:as_json), "pending" => pending_count, "consumed" => @rules.size - pending_count }
      end

      private

      def build(spec)
        unknown = spec.keys - FIELDS
        raise Error.invalid_control("Unknown fault rule fields: #{unknown.join(", ")}") if unknown.any?

        operation = spec["operation"]
        raise Error.invalid_control("operation must be one of: #{@match_keys.keys.join(", ")}") unless @match_keys.key?(operation)

        status = spec["status"]
        raise Error.invalid_control("status must be one of: #{STATUSES.join(", ")}") unless status.is_a?(Integer) && STATUSES.include?(status)

        attempt = spec.fetch("attempt", 1)
        raise Error.invalid_control("attempt must be a whole number from 1 to #{MAX_ATTEMPT}") unless attempt.is_a?(Integer) && attempt.between?(1, MAX_ATTEMPT)

        retry_after = spec["retry_after"]
        raise Error.invalid_control("retry_after must be a whole number of seconds from 0 to #{MAX_RETRY_AFTER}") unless retry_after.nil? || (retry_after.is_a?(Integer) && retry_after.between?(0, MAX_RETRY_AFTER))

        Rule.new(@rules.size + 1, operation, match_for(operation, spec.fetch("match", {})), attempt, status, retry_after, 0, nil)
      end

      def match_for(operation, match)
        keys = Array(@match_keys[operation])
        raise Error.invalid_control("match must be a JSON object") unless match.is_a?(Hash)
        return match if match.empty?
        raise Error.invalid_control(keys.any? ? "#{operation} rules can only match on #{keys.join(" and ")}" : "#{operation} rules cannot use match") unless (match.keys - keys).empty?

        match.each do |key, value|
          if NUMBERED_MATCH_KEYS.include?(key)
            raise Error.invalid_control("match.#{key} must be a positive whole number") unless value.is_a?(Integer) && value.positive?
          else
            raise Error.invalid_control("match.#{key} must be a string") unless value.is_a?(String)
          end
        end
        match
      end
    end
  end
end
