module FilesMockServer
  class AutomationAPI < Grape::API
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
    get "/api/rest/v1/automations" do
      status 200
      [ { "id" => 1, "always_serialize_jobs" => true, "always_overwrite_size_matching_files" => true, "automation" => "create_folder", "deleted" => true, "description" => "example", "destination_replace_from" => "example", "destination_replace_to" => "example", "destinations" => [ "destination" ], "disabled" => true, "exclude_pattern" => "path/to/exclude/*", "import_urls" => [ { "name" => "users.json", "url" => "http://example.com/users", "method" => "POST", "headers" => { "Content-Type" => "application/json" }, "content" => { "group" => "support" } } ], "flatten_destination_structure" => true, "group_ids" => [ 1, 2 ], "ignore_locked_folders" => true, "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "legacy_folder_matching" => true, "name" => "example", "overwrite_files" => true, "path" => "example", "path_time_zone" => "Eastern Time (US & Canada)", "recurring_day" => 25, "retry_on_failure_interval_in_minutes" => 60, "retry_on_failure_number_of_attempts" => 10, "schedule" => { "days_of_week" => [ 0, 2, 4 ], "times_of_day" => [ "06:30", "14:30" ], "time_zone" => "Eastern Time (US & Canada)" }, "human_readable_schedule" => "Triggered every Monday, Wednesday at 6:30 AM,\n  2:30 PM Eastern Time (US & Canada) TZ", "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "source" => "example", "sync_ids" => [ 1, 2 ], "trigger_actions" => [ "create" ], "trigger" => "daily", "user_id" => 1, "user_ids" => [ 1, 2 ], "value" => { "limit" => "1" }, "webhook_url" => "https://app.files.com/api/webhooks/abc123" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "always_serialize_jobs" => true, "always_overwrite_size_matching_files" => true, "automation" => "create_folder", "deleted" => true, "description" => "example", "destination_replace_from" => "example", "destination_replace_to" => "example", "destinations" => [ "destination" ], "disabled" => true, "exclude_pattern" => "path/to/exclude/*", "import_urls" => [ { "name" => "users.json", "url" => "http://example.com/users", "method" => "POST", "headers" => { "Content-Type" => "application/json" }, "content" => { "group" => "support" } } ], "flatten_destination_structure" => true, "group_ids" => [ 1, 2 ], "ignore_locked_folders" => true, "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "legacy_folder_matching" => true, "name" => "example", "overwrite_files" => true, "path" => "example", "path_time_zone" => "Eastern Time (US & Canada)", "recurring_day" => 25, "retry_on_failure_interval_in_minutes" => 60, "retry_on_failure_number_of_attempts" => 10, "schedule" => { "days_of_week" => [ 0, 2, 4 ], "times_of_day" => [ "06:30", "14:30" ], "time_zone" => "Eastern Time (US & Canada)" }, "human_readable_schedule" => "Triggered every Monday, Wednesday at 6:30 AM,\n  2:30 PM Eastern Time (US & Canada) TZ", "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "source" => "example", "sync_ids" => [ 1, 2 ], "trigger_actions" => [ "create" ], "trigger" => "daily", "user_id" => 1, "user_ids" => [ 1, 2 ], "value" => { "limit" => "1" }, "webhook_url" => "https://app.files.com/api/webhooks/abc123" }
    end

    params do
      optional :source, type: String
      optional :destinations, type: [ String ]
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :sync_ids, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :always_overwrite_size_matching_files, type: Boolean
      optional :always_serialize_jobs, type: Boolean
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :exclude_pattern, type: String
      optional :import_urls, type: [ Hash ]
      optional :flatten_destination_structure, type: Boolean
      optional :ignore_locked_folders, type: Boolean
      optional :legacy_folder_matching, type: Boolean
      optional :name, type: String
      optional :overwrite_files, type: Boolean
      optional :path_time_zone, type: String
      optional :retry_on_failure_interval_in_minutes, type: Integer
      optional :retry_on_failure_number_of_attempts, type: Integer
      optional :trigger, type: String
      optional :trigger_actions, type: [ String ]
      optional :value, type: Hash
      optional :recurring_day, type: Integer
      requires :automation, type: String
    end
    post "/api/rest/v1/automations" do
      status 201
      { "id" => 1, "always_serialize_jobs" => true, "always_overwrite_size_matching_files" => true, "automation" => "create_folder", "deleted" => true, "description" => "example", "destination_replace_from" => "example", "destination_replace_to" => "example", "destinations" => [ "destination" ], "disabled" => true, "exclude_pattern" => "path/to/exclude/*", "import_urls" => [ { "name" => "users.json", "url" => "http://example.com/users", "method" => "POST", "headers" => { "Content-Type" => "application/json" }, "content" => { "group" => "support" } } ], "flatten_destination_structure" => true, "group_ids" => [ 1, 2 ], "ignore_locked_folders" => true, "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "legacy_folder_matching" => true, "name" => "example", "overwrite_files" => true, "path" => "example", "path_time_zone" => "Eastern Time (US & Canada)", "recurring_day" => 25, "retry_on_failure_interval_in_minutes" => 60, "retry_on_failure_number_of_attempts" => 10, "schedule" => { "days_of_week" => [ 0, 2, 4 ], "times_of_day" => [ "06:30", "14:30" ], "time_zone" => "Eastern Time (US & Canada)" }, "human_readable_schedule" => "Triggered every Monday, Wednesday at 6:30 AM,\n  2:30 PM Eastern Time (US & Canada) TZ", "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "source" => "example", "sync_ids" => [ 1, 2 ], "trigger_actions" => [ "create" ], "trigger" => "daily", "user_id" => 1, "user_ids" => [ 1, 2 ], "value" => { "limit" => "1" }, "webhook_url" => "https://app.files.com/api/webhooks/abc123" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/automations/:id/manual_run" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :source, type: String
      optional :destinations, type: [ String ]
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :sync_ids, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :always_overwrite_size_matching_files, type: Boolean
      optional :always_serialize_jobs, type: Boolean
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :exclude_pattern, type: String
      optional :import_urls, type: [ Hash ]
      optional :flatten_destination_structure, type: Boolean
      optional :ignore_locked_folders, type: Boolean
      optional :legacy_folder_matching, type: Boolean
      optional :name, type: String
      optional :overwrite_files, type: Boolean
      optional :path_time_zone, type: String
      optional :retry_on_failure_interval_in_minutes, type: Integer
      optional :retry_on_failure_number_of_attempts, type: Integer
      optional :trigger, type: String
      optional :trigger_actions, type: [ String ]
      optional :value, type: Hash
      optional :recurring_day, type: Integer
      optional :automation, type: String
    end
    patch "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "always_serialize_jobs" => true, "always_overwrite_size_matching_files" => true, "automation" => "create_folder", "deleted" => true, "description" => "example", "destination_replace_from" => "example", "destination_replace_to" => "example", "destinations" => [ "destination" ], "disabled" => true, "exclude_pattern" => "path/to/exclude/*", "import_urls" => [ { "name" => "users.json", "url" => "http://example.com/users", "method" => "POST", "headers" => { "Content-Type" => "application/json" }, "content" => { "group" => "support" } } ], "flatten_destination_structure" => true, "group_ids" => [ 1, 2 ], "ignore_locked_folders" => true, "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "legacy_folder_matching" => true, "name" => "example", "overwrite_files" => true, "path" => "example", "path_time_zone" => "Eastern Time (US & Canada)", "recurring_day" => 25, "retry_on_failure_interval_in_minutes" => 60, "retry_on_failure_number_of_attempts" => 10, "schedule" => { "days_of_week" => [ 0, 2, 4 ], "times_of_day" => [ "06:30", "14:30" ], "time_zone" => "Eastern Time (US & Canada)" }, "human_readable_schedule" => "Triggered every Monday, Wednesday at 6:30 AM,\n  2:30 PM Eastern Time (US & Canada) TZ", "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "source" => "example", "sync_ids" => [ 1, 2 ], "trigger_actions" => [ "create" ], "trigger" => "daily", "user_id" => 1, "user_ids" => [ 1, 2 ], "value" => { "limit" => "1" }, "webhook_url" => "https://app.files.com/api/webhooks/abc123" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/automations/:id" do
      status 204
      body false
    end
  end
end
