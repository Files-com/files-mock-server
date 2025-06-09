module FilesMockServer
  class ExavaultApiRequestLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/exavault_api_request_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "endpoint" => "example", "version" => 1, "request_ip" => "example", "request_method" => "example", "error_type" => "example", "error_message" => "example", "user_agent" => "example", "response_code" => 1, "success" => true, "duration_ms" => 1, "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
