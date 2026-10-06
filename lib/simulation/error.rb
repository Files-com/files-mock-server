module FilesMockServer
  module Simulation
    # An error response in the Files.com API shape: {"error", "http-code", "title", "type"} and, for
    # errors that carry details such as a lockout region mismatch's host, "data".
    class Error < StandardError
      attr_reader :status, :type, :title, :headers, :data

      def initialize(status, type, title, message, headers: {}, data: nil)
        super(message)
        @status = status
        @type = type
        @title = title
        @headers = headers
        @data = data
      end

      def to_rack
        body = { "error" => message, "http-code" => status, "title" => title, "type" => type }
        body["data"] = data if data
        [ status, { "content-type" => "application/json", "x-files-error-class" => type }.merge(headers), [ JSON.generate(body) ] ]
      end

      # Statuses, types and messages below match the Files.com API, where bad-request errors are HTTP 422.
      def self.not_found
        new(404, "not-found", "Not Found", "Not Found.  This may be related to your permissions.")
      end

      # The not-found answer a Files.com site sent in Spanish to a file lookup
      # (GET /file_actions/metadata/{path}) with Accept-Language: es; only the message differs from
      # the English answer. It is the simulator's only translation: any other Accept-Language gets
      # the English answer, and so does every other error.
      def self.not_found_for(accept_language)
        return not_found unless accept_language == "es"

        new(404, "not-found", "Not Found", "No se ha encontrado. Esto puede estar relacionado con tus permisos.")
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

      def self.request_params_invalid(message, status: 422)
        new(status, "bad-request/request-params-invalid", "Request Params Invalid", "Invalid request parameters: #{message}")
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

      # A recorded copy or move to an existing destination answers "The destination exists."
      def self.destination_exists(message = "Destination already exists.")
        new(422, "processing-failure/destination-exists", "Destination Exists", message)
      end

      # A lock that conflicts with held locks. The message is the Files.com lock model's own list of
      # them ("exclusive lock TOKEN at /PATH", joined with ", ").
      def self.resource_locked(message)
        new(422, "processing-failure/resource-locked", "Resource Locked", message)
      end

      def self.folder_not_empty(path)
        new(422, "processing-failure/folder-not-empty", "Folder Not Empty", "The folder #{path.empty? ? "/" : path} is not empty.")
      end

      # The API refuses a path with a folder name ending in whitespace: a request's path (its path
      # helper) and a copy, move, unzip or ZIP destination (its destination helper). The type and
      # status are the API's; the message is the simulator's.
      def self.path_cannot_have_trailing_whitespace
        new(422, "bad-request/path-cannot-have-trailing-whitespace", "Path Cannot Have Trailing Whitespace", "A folder name in the path ends in whitespace (the simulator does not model Files.com's message).")
      end

      # The API's path helper refuses a request path holding a zero-width space. The type and status
      # are the API's; the message is the simulator's.
      def self.invalid_path
        new(422, "bad-request/invalid-path", "Invalid Path", "The path contains a zero-width space (the simulator does not model Files.com's message).")
      end

      # What the API answers an exception none of its handlers maps: BaseApi's catch-all outside tests
      # renders this message and a string "http-code" through its error formatter, with no error class
      # header. The simulator answers it only where the pinned source raises such an exception (see
      # ServerError); the service's other headers are not modeled.
      def self.server_error
        ServerError.new(500, nil, nil, "Internal server error, please contact support or the person who created your account.")
      end

      # What the API answers a create whose model save fails its validations after the request's
      # parameters were admitted: Create#save raises ApiError::ModelSaveError with the model, and
      # ErrorResponse presents the model's errors (see ModelSaveError). failures: [ field, error key, full
      # message ], in the model's validation order.
      def self.model_save_error(failures)
        ModelSaveError.new(failures)
      end

      def self.folder_must_not_be_a_file
        new(422, "bad-request/folder-must-not-be-a-file", "Folder Must Not Be A File", "The parent folder is a file.")
      end

      def self.cannot_download_directory
        new(422, "bad-request/cannot-download-directory", "Cannot Download Directory", "A folder cannot be downloaded.")
      end

      # What zip_list and unzip answer for a folder, and zip_list for a file that is not a readable ZIP.
      def self.folders_not_allowed
        new(422, "bad-request/folders-not-allowed", "Folders Not Allowed", "You are not allowed to create folders here.")
      end

      def self.invalid_zip_file
        new(422, "processing-failure/invalid-zip-file", "Invalid Zip File", "Invalid ZIP file.")
      end

      # HTTP's 416 for a download range that starts past the end of the file (RFC 9110, section 15.5.17),
      # with the API's invalid-range error.
      def self.range_not_satisfiable(size)
        new(416, "processing-failure/invalid-range", "Invalid Range", "Invalid range", headers: { "content-range" => "bytes */#{size}" })
      end

      # The typed conflict for a download URL whose file has changed, which the Go SDK answers by
      # requesting a new URL and restarting the download.
      # The download identity contract answers a changed source on the byte route with 412.
      def self.download_source_changed(status = 409)
        new(status, "download_source_changed", "Download Source Changed", "The source file changed while it was being downloaded. Request a new download URL and restart from the beginning.")
      end

      # What Files.com answers a download identity parameter that is malformed or not allowed with
      # the request (400 bad-request/request-params-invalid), and a renewal whose version can no longer
      # be downloaded (422 processing-failure/download-identity-unavailable).
      def self.identity_parameter(name)
        request_params_invalid(name, status: 400)
      end

      def self.download_identity_unavailable
        new(422, "processing-failure/download-identity-unavailable", "Download Identity Unavailable", "That version of the file can no longer be downloaded.")
      end

      # A request that breaks a rule the reset's transfer profile advertised (Profile::Upload).
      def self.profile_violation(status, message, headers: {})
        new(status, "simulation/profile-violation", "Transfer Profile Violation", message, headers:)
      end

      # An error in a storage provider's XML shape, for transfer URLs.
      def self.storage(status, code, message)
        StorageError.new(status, code, code, message)
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

      # An error a fault rule answers with: "simulation/injected-fault" unless the rule names a Files.com
      # error type and message, with the rule's "data" object when it has one. The x-files-mock-fault
      # header names the rule, so a recorded exchange shows the error was injected.
      def self.injected_fault(rule)
        headers = { "x-files-mock-fault" => rule.id.to_s }
        headers["retry-after"] = rule.retry_after.to_s if rule.retry_after
        title = rule.type ? rule.type.split("/").last.split("-").map(&:capitalize).join(" ") : Rack::Utils::HTTP_STATUS_CODES.fetch(rule.status)
        new(rule.status, rule.type || "simulation/injected-fault", title, rule.message || "Simulated #{rule.status} response from fault rule #{rule.id}", headers:, data: rule.data)
      end

      # A fault rule that closes or cuts the connection on a server that cannot.
      def self.fault_unavailable(rule)
        not_supported("Fault rule #{rule.id} (#{rule.kind}) closes or cuts the connection, which this server cannot do; run the simulator with bundle exec puma. The request was not applied.")
      end
    end

    # The API's catch-all 500 body: Formatters.error_json_formatter turns BaseApi's
    # { message:, "http-code" => "500" } into { "error" => message, "http-code" => "500" }.
    class ServerError < Error
      def to_rack
        [ status, { "content-type" => "application/json" }.merge(headers), [ JSON.generate("error" => message, "http-code" => status.to_s) ] ]
      end
    end

    # The API's model-save failure as ErrorResponse and ErrorResponseEntity present it: "error" joins the
    # model's full messages, "model_errors" groups them by field, "model_error_keys" gives each error's key
    # and "errors" lists them, before the title and type (with the error class header).
    class ModelSaveError < Error
      def initialize(failures)
        super(422, "processing-failure/model-save-error", "Model Save Error", failures.map(&:last).join(", "))
        @failures = failures
      end

      def to_rack
        by_field = @failures.group_by(&:first)
        body = { "error" => message, "http-code" => status, "model_errors" => by_field.transform_values { |list| list.map(&:last) },
                 "model_error_keys" => by_field.transform_values { |list| list.map { |failure| failure[1] } }, "errors" => @failures.map(&:last), "title" => title, "type" => type }
        [ status, { "content-type" => "application/json", "x-files-error-class" => type }.merge(headers), [ JSON.generate(body) ] ]
      end
    end

    # A storage provider's XML error, which transfer URLs answer with instead of an API error body.
    class StorageError < Error
      def to_rack
        body = %(<?xml version="1.0" encoding="UTF-8"?>\n<Error><Code>#{type}</Code><Message>#{message}</Message></Error>\n)
        [ status, { "content-type" => "application/xml" }.merge(headers), [ body ] ]
      end
    end
  end
end
