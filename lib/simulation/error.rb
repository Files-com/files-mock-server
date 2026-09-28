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

      def self.request_params_required(name)
        new(422, "bad-request/request-params-required", "Request Params Required", "Required request parameter missing: #{name}")
      end

      def self.file_upload_not_found(ref)
        new(404, "not-found/file-upload-not-found", "File Upload Not Found", "File Upload for id #{ref} not found.")
      end

      def self.part_number_too_large
        new(422, "bad-request/part-number-too-large", "Part Number Too Large", "Part number too large")
      end

      def self.invalid_etags(message = "Invalid etags")
        new(422, "bad-request/invalid-etags", "Invalid Etags", message)
      end

      def self.file_not_uploaded
        new(422, "processing-failure/file-not-uploaded", "File Not Uploaded", "File not uploaded")
      end

      # HTTP's 416 for a download range that starts past the end of the file (RFC 9110, section 15.5.17),
      # with the API's invalid-range error.
      def self.range_not_satisfiable(size)
        new(416, "processing-failure/invalid-range", "Invalid Range", "Invalid range", headers: { "content-range" => "bytes */#{size}" })
      end

      # The typed conflict for a download URL whose file has changed, which the Go SDK answers by
      # requesting a new URL and restarting the download.
      def self.download_source_changed
        new(409, "download_source_changed", "Download Source Changed", "The source file changed while it was being downloaded. Request a new download URL and restart from the beginning.")
      end

      # Errors that only the simulator produces use the "simulation/" type prefix.
      def self.not_supported(message)
        new(501, "simulation/not-supported", "Not Simulated", message)
      end

      def self.limit_exceeded(status, message)
        new(status, "simulation/limit-exceeded", "Simulation Limit Exceeded", message)
      end

      def self.body_too_large(limit)
        limit_exceeded(413, "Request bodies are limited to #{limit} bytes (FILES_MOCK_MAX_BODY_BYTES)")
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
