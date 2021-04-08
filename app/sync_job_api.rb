module FilesMockServer
  class SyncJobAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/sync_jobs" do
      status 200
      [ { "queued_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "status" => "", "regional_worker_status" => "", "uuid" => "", "folder_behavior_id" => 1 } ]
    end
  end
end
