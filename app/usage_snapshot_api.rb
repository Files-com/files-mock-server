module FilesMockServer
  class UsageSnapshotAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/usage_snapshots" do
      status 200
      [ { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "high_water_user_count" => 1.0, "current_storage" => 1.0, "high_water_storage" => 1.0, "usage_by_top_level_dir" => { "key" => "example value" }, "root_storage" => 1.0, "deleted_files_counted_in_minimum" => 1.0, "deleted_files_storage" => 1.0, "total_billable_usage" => 1.0, "total_billable_transfer_usage" => 1.0, "bytes_sent" => 1.0, "sync_bytes_received" => 1.0, "sync_bytes_sent" => 1.0 } ]
    end
  end
end
