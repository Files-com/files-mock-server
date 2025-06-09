module FilesMockServer
  class OutboundConnectionLogAPI < Grape::API
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
    get "/api/rest/v1/outbound_connection_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "path" => "example", "client_ip" => "example", "src_remote_server_id" => 1, "dest_remote_server_id" => 1, "operation" => "example", "error_message" => "example", "error_operation" => "example", "error_type" => "example", "status" => "example", "duration_ms" => 1, "bytes_uploaded" => 1, "bytes_downloaded" => 1, "list_count" => 1, "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
