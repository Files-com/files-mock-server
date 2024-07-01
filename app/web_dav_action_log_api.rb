module FilesMockServer
  class WebDavActionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/web_dav_action_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "remote_ip" => "example", "server_ip" => "example", "username" => "example", "auth_ciphers" => "example", "action_type" => "example", "path" => "example", "true_path" => "example", "name" => "example", "http_method" => "example", "http_path" => "example", "http_response_code" => 1, "size" => 1, "entries_returned" => 1, "success" => true, "duration_ms" => 1 } ]
    end
  end
end
