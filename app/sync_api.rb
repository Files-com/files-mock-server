module FilesMockServer
  class SyncAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/syncs" do
      status 200
      [ { "id" => 1, "name" => "example", "description" => "example", "site_id" => 1, "user_id" => 1, "src_path" => "example", "dest_path" => "example", "src_remote_server_id" => 1, "dest_remote_server_id" => 1, "two_way" => true, "keep_after_copy" => true, "delete_empty_folders" => true, "disabled" => true, "trigger" => "example", "trigger_file" => "example", "include_patterns" => [ "example" ], "exclude_patterns" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "sync_interval_minutes" => 1, "interval" => "week", "recurring_day" => 25, "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us_dc", "latest_sync_run" => { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/syncs/:id" do
      status 200
      { "id" => 1, "name" => "example", "description" => "example", "site_id" => 1, "user_id" => 1, "src_path" => "example", "dest_path" => "example", "src_remote_server_id" => 1, "dest_remote_server_id" => 1, "two_way" => true, "keep_after_copy" => true, "delete_empty_folders" => true, "disabled" => true, "trigger" => "example", "trigger_file" => "example", "include_patterns" => [ "example" ], "exclude_patterns" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "sync_interval_minutes" => 1, "interval" => "week", "recurring_day" => 25, "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us_dc", "latest_sync_run" => { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" } }
    end

    params do
      optional :name, type: String
      optional :description, type: String
      optional :src_path, type: String
      optional :dest_path, type: String
      optional :src_remote_server_id, type: Integer
      optional :dest_remote_server_id, type: Integer
      optional :keep_after_copy, type: Boolean
      optional :delete_empty_folders, type: Boolean
      optional :disabled, type: Boolean
      optional :interval, type: String
      optional :trigger, type: String
      optional :trigger_file, type: String
      optional :holiday_region, type: String
      optional :sync_interval_minutes, type: Integer
      optional :recurring_day, type: Integer
      optional :schedule_time_zone, type: String
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
    end
    post "/api/rest/v1/syncs" do
      status 201
      { "id" => 1, "name" => "example", "description" => "example", "site_id" => 1, "user_id" => 1, "src_path" => "example", "dest_path" => "example", "src_remote_server_id" => 1, "dest_remote_server_id" => 1, "two_way" => true, "keep_after_copy" => true, "delete_empty_folders" => true, "disabled" => true, "trigger" => "example", "trigger_file" => "example", "include_patterns" => [ "example" ], "exclude_patterns" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "sync_interval_minutes" => 1, "interval" => "week", "recurring_day" => 25, "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us_dc", "latest_sync_run" => { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" } }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/syncs/:id/dry_run" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/syncs/:id/manual_run" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :description, type: String
      optional :src_path, type: String
      optional :dest_path, type: String
      optional :src_remote_server_id, type: Integer
      optional :dest_remote_server_id, type: Integer
      optional :keep_after_copy, type: Boolean
      optional :delete_empty_folders, type: Boolean
      optional :disabled, type: Boolean
      optional :interval, type: String
      optional :trigger, type: String
      optional :trigger_file, type: String
      optional :holiday_region, type: String
      optional :sync_interval_minutes, type: Integer
      optional :recurring_day, type: Integer
      optional :schedule_time_zone, type: String
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
    end
    patch "/api/rest/v1/syncs/:id" do
      status 200
      { "id" => 1, "name" => "example", "description" => "example", "site_id" => 1, "user_id" => 1, "src_path" => "example", "dest_path" => "example", "src_remote_server_id" => 1, "dest_remote_server_id" => 1, "two_way" => true, "keep_after_copy" => true, "delete_empty_folders" => true, "disabled" => true, "trigger" => "example", "trigger_file" => "example", "include_patterns" => [ "example" ], "exclude_patterns" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "sync_interval_minutes" => 1, "interval" => "week", "recurring_day" => 25, "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us_dc", "latest_sync_run" => { "id" => 1, "body" => "example", "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "dest_remote_server_type" => "example", "dry_run" => true, "errored_files" => 1, "estimated_bytes_count" => 1, "event_errors" => [ "example" ], "log_url" => "https://www.example.com/log_file.txt", "runtime" => 1.0, "site_id" => 1, "src_remote_server_type" => "example", "status" => "example", "successful_files" => 1, "sync_id" => 1, "sync_name" => "Azure to SharePoint Sync", "updated_at" => "2000-01-01T01:00:00Z" } }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/syncs/:id" do
      status 204
      body false
    end
  end
end
