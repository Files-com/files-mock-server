module FilesMockServer
  module Simulation
    # An error response in the Files.com API shape: {"error", "http-code", "title", "type"}.
    class Error < StandardError
      attr_reader :status, :type, :title, :headers

      def initialize(status, type, title, message, headers: {})
        super(message)
        @status = status
        @type = type
        @title = title
        @headers = headers
      end

      def to_rack
        body = { "error" => message, "http-code" => status, "title" => title, "type" => type }
        [ status, { "content-type" => "application/json", "x-files-error-class" => type }.merge(headers), [ JSON.generate(body) ] ]
      end

      # Statuses, types and messages below match the Files.com API, where bad-request errors are HTTP 422.
      def self.not_found
        new(404, "not-found", "Not Found", "Not Found.  This may be related to your permissions.")
      end

      def self.bad_request(message)
        new(422, "bad-request", "Bad Request", message)
      end

      def self.invalid_body(message)
        new(422, "bad-request/invalid-body", "Invalid Body", message)
      end

      def self.invalid_cursor
        new(422, "bad-request/invalid-cursor", "Invalid Cursor", "Invalid cursor")
      end

      def self.request_params_invalid(message)
        new(422, "bad-request/request-params-invalid", "Request Params Invalid", "Invalid request parameters: #{message}")
      end

      # Errors that only the simulator produces use the "simulation/" type prefix.
      def self.not_supported(message)
        new(501, "simulation/not-supported", "Not Simulated", message)
      end

      def self.limit_exceeded(status, message)
        new(status, "simulation/limit-exceeded", "Simulation Limit Exceeded", message)
      end

      def self.stale_request
        new(409, "simulation/stale-request", "Stale Request", "The simulator was reset while this request was in flight, so the request was not applied.")
      end

      def self.invalid_control(message, status: 400)
        new(status, "simulation/invalid-control-request", "Invalid Control Request", message)
      end

      def self.injected_fault(rule)
        headers = rule.retry_after ? { "retry-after" => rule.retry_after.to_s } : {}
        new(rule.status, "simulation/injected-fault", Rack::Utils::HTTP_STATUS_CODES.fetch(rule.status), "Simulated #{rule.status} response from fault rule #{rule.id}", headers:)
      end
    end
  end
end
