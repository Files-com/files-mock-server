module FilesMockServer
  class SyncRunAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/sync_runs" do
      status 200
      [ { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sync_runs/:id" do
      status 200
      { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
