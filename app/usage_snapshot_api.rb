module FilesMockServer
  class UsageSnapshotAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/usage_snapshots" do
      status 200
      [ { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "high_water_user_count" => 1, "current_storage" => 1, "high_water_storage" => 1, "root_storage" => 1, "deleted_files_counted_in_minimum" => 1, "deleted_files_storage" => 1, "total_billable_usage" => 1, "total_billable_transfer_usage" => 1, "bytes_sent" => 1, "sync_bytes_received" => 1, "sync_bytes_sent" => 1, "usage_by_top_level_dir" => [ { "dir" => "dir", "size" => 100, "count" => 10 } ] } ]
    end
  end
end
