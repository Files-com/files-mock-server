module FilesMockServer
  class ExavaultApiRequestLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/exavault_api_request_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "endpoint" => "example", "version" => "example", "request_ip" => "example", "request_method" => "example", "error_type" => "example", "error_message" => "example", "user_agent" => "example", "response_code" => 1, "success" => true, "duration_ms" => 1 } ]
    end
  end
end
