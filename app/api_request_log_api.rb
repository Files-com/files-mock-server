module FilesMockServer
  class ApiRequestLogAPI < Grape::API
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
    get "/api/rest/v1/api_request_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "api_key_id" => 1, "api_key_prefix" => "example", "user_id" => 1, "username" => "example", "user_is_from_parent_site" => true, "interface" => "example", "request_method" => "example", "request_path" => "example", "request_ip" => "example", "request_host" => "example", "request_id" => "example", "api_name" => "example", "user_agent" => "example", "error_type" => "example", "error_message" => "example", "response_code" => 1, "success" => true, "duration_ms" => 1, "impersonator_user_id" => 1, "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
