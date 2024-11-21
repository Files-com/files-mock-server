module FilesMockServer
  class OutboundConnectionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/outbound_connection_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "path" => "example", "client_ip" => "example", "src_remote_server_id" => "example", "dest_remote_server_id" => "example", "operation" => "example", "error_message" => "example", "error_operation" => "example", "error_type" => "example", "status" => "example", "duration_ms" => 1, "bytes_uploaded" => 1, "bytes_downloaded" => 1, "list_count" => 1 } ]
    end

    params do
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/outbound_connection_logs/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
