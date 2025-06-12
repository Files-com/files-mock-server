module FilesMockServer
  class PublicHostingRequestLogAPI < Grape::API
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
    get "/api/rest/v1/public_hosting_request_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "remote_ip" => "example", "server_ip" => "example", "hostname" => "example", "path" => "example", "responseCode" => 1, "success" => true, "duration_ms" => 1, "created_at" => "2000-01-01T01:00:00Z", "bytes_transferred" => 1, "http_method" => "GET" } ]
    end
  end
end
