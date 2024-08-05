module FilesMockServer
  class UsageDailySnapshotAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/usage_daily_snapshots" do
      status 200
      [ { "id" => 1, "date" => "2000-01-01T01:00:00Z", "api_usage_available" => true, "read_api_usage" => 1, "write_api_usage" => 1, "user_count" => 1, "current_storage" => 1, "deleted_files_storage" => 1, "deleted_files_counted_in_minimum" => 1, "root_storage" => 1, "usage_by_top_level_dir" => { "key" => "example value" } } ]
    end
  end
end
