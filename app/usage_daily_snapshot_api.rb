module FilesMockServer
  class UsageDailySnapshotAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api/rest/v1/usage_daily_snapshots" do
      status 200
      [ { "id" => 1, "date" => "2020-11-21", "current_storage" => "65536", "usage_by_top_level_dir" => [] } ]
    end
  end
end
