module FilesMockServer
  class SyncApiUsageSnapshotReportAPI < Grape::API
    format :json

    params do
      optional :start_time, type: String
      optional :end_time, type: String
      optional :uuid, type: String
      optional :auth_cache_hits, type: Integer
      optional :auth_cache_misses, type: Integer
      optional :auth_api_requests_for_sftp, type: Integer
      optional :auth_api_requests_for_ftp, type: Integer
      optional :auth_api_requests_for_dav, type: Integer
      optional :auth_api_requests_for_desktop, type: Integer
      optional :auth_api_requests_for_restapi, type: Integer
      optional :number_of_sync_api_usage_snapshots, type: Integer
      optional :sync_api_usage_snapshots, type: [ Hash ]
    end
    post "/api/rest/v1/sync_api_usage_snapshot_reports" do
      status 201
      { "start_time" => "2000-01-01T01:00:00Z", "end_time" => "2000-01-01T01:00:00Z", "uuid" => "example", "auth_cache_hits" => 1, "auth_cache_misses" => 1, "auth_api_requests_for_sftp" => 1, "auth_api_requests_for_ftp" => 1, "auth_api_requests_for_dav" => 1, "auth_api_requests_for_desktop" => 1, "auth_api_requests_for_restapi" => 1, "number_of_sync_api_usage_snapshots" => 1, "sync_api_usage_snapshots" => [] }
    end
  end
end
