module FilesMockServer
  class SyncLogAPI < Grape::API
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
    get "/api/rest/v1/sync_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "sync_id" => 1, "external_event_id" => 1, "sync_run_id" => 1, "error_type" => "example", "message" => "example", "operation" => "example", "path" => "example", "size" => 1, "file_type" => "example", "status" => "example", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
