module FilesMockServer
  class SyncLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/sync_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "sync_id" => 1, "external_event_id" => 1, "error_type" => "example", "message" => "example", "operation" => "example", "path" => "example", "size" => "example", "file_type" => "example", "status" => "example" } ]
    end

    params do
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/sync_logs/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
