module FilesMockServer
  class AutomationVersionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      requires :automation_id, type: Integer
    end
    get "/api/rest/v1/automation_versions" do
      status 200
      [ { "id" => 1, "automation_id" => 1, "workspace_id" => 1, "version" => 1, "created_at" => "2000-01-01T01:00:00Z", "user_id" => 1, "username" => "example", "api_key_id" => 1, "definition" => { "schema_version" => 1, "nodes" => [ { "id" => "trigger", "type" => "trigger_manual" }, { "id" => "create_reports", "type" => "create_folder", "config" => { "destinations" => [ "reports/" ] } } ], "edges" => [ { "from" => "trigger", "to" => "create_reports" } ] } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automation_versions/:id" do
      status 200
      { "id" => 1, "automation_id" => 1, "workspace_id" => 1, "version" => 1, "created_at" => "2000-01-01T01:00:00Z", "user_id" => 1, "username" => "example", "api_key_id" => 1, "definition" => { "schema_version" => 1, "nodes" => [ { "id" => "trigger", "type" => "trigger_manual" }, { "id" => "create_reports", "type" => "create_folder", "config" => { "destinations" => [ "reports/" ] } } ], "edges" => [ { "from" => "trigger", "to" => "create_reports" } ] } }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/automation_versions/:id/restore" do
      status 200
      { "id" => 1, "workspace_id" => 1, "always_serialize_jobs" => true, "always_overwrite_size_matching_files" => true, "automation" => "create_folder", "converted_automation_id" => 1, "deleted" => true, "description" => "example", "definition" => { "schema_version" => 1, "nodes" => [ { "id" => "trigger", "type" => "trigger_manual" }, { "id" => "create_reports", "type" => "create_folder", "config" => { "destinations" => [ "reports/" ] } } ], "edges" => [ { "from" => "trigger", "to" => "create_reports" } ] }, "destination_replace_from" => "example", "destination_replace_to" => "example", "destinations" => [ "destination" ], "disabled" => true, "exclude_pattern" => "path/to/exclude/*", "import_urls" => [ { "name" => "users.json", "url" => "https://example.com/users", "method" => "post", "headers" => { "Content-Type" => "application/json" }, "content" => { "group" => "support" } } ], "inbound_email_address" => "example-automation-abc123@inbox.files.com", "flatten_destination_structure" => true, "group_ids" => [ 1, 2 ], "ignore_locked_folders" => true, "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "legacy_folder_matching" => false, "name" => "example", "original_automation_id" => 1, "overwrite_files" => true, "path" => "example", "path_time_zone" => "Eastern Time (US & Canada)", "version" => 1, "recurring_day" => 25, "recurring_days" => [ 1, 15 ], "schedule_id" => 1, "retry_on_failure_interval_in_minutes" => 60, "retry_on_failure_number_of_attempts" => 10, "schedule" => { "days_of_week" => [ 0, 2, 4 ], "times_of_day" => [ "06:30", "14:30" ], "time_zone" => "Eastern Time (US & Canada)" }, "human_readable_schedule" => "Triggered every Monday, Wednesday at 6:30 AM,\n  2:30 PM Eastern Time (US & Canada) TZ", "schedule_days_of_week" => [ 0, 2, 4 ], "schedule_interval_minutes" => 15, "schedule_times_of_day" => [ "06:30", "14:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "source" => "example", "sync_ids" => [ 1, 2 ], "trigger_actions" => [ "create" ], "trigger" => "daily", "user_id" => 1, "user_ids" => [ 1, 2 ], "value" => { "limit" => "1" }, "webhook_url" => "https://app.files.com/api/webhooks/abc123", "holiday_region" => "us_dc" }
    end
  end
end
