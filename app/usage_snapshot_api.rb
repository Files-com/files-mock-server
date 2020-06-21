module FilesMockServer
  class UsageSnapshotAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/usage_snapshots" do
      status 200
      [{"id"=>1, "start_at"=>"2000-01-01T01:00:00Z", "end_at"=>"2000-01-01T01:00:00Z", "created_at"=>"2000-01-01T01:00:00Z", "current_storage"=>"", "high_water_storage"=>"", "total_downloads"=>1, "total_uploads"=>1, "updated_at"=>"2000-01-01T01:00:00Z", "usage_by_top_level_dir"=>"", "root_storage"=>"", "deleted_files_counted_in_minimum"=>"", "deleted_files_storage"=>""}]
    end
  end
end
