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
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/usage_daily_snapshots" do
      status 200
      [ { "id" => 1, "date" => "2020-11-21", "current_storage" => "65536", "usage_by_top_level_dir" => [] } ]
    end
  end
end
