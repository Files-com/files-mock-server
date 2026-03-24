module FilesMockServer
  class ExpectationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/expectations" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Daily Vendor Feed", "description" => "Wait for the vendor CSV every morning.", "path" => "incoming/vendor_a", "source" => "*.csv", "exclude_pattern" => "*.tmp", "disabled" => true, "expectations_version" => 1, "trigger" => "manual", "interval" => "day", "recurring_day" => 3, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:00" ], "schedule_time_zone" => "UTC", "holiday_region" => "us", "lookback_interval" => 3600, "late_acceptance_interval" => 900, "inactivity_interval" => 300, "max_open_interval" => 43200, "criteria" => { "count" => { "exact" => 1 }, "extensions" => [ "csv" ] }, "last_evaluated_at" => "2000-01-01T01:00:00Z", "last_success_at" => "2000-01-01T01:00:00Z", "last_failure_at" => "2000-01-01T01:00:00Z", "last_result" => "success", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/expectations/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Daily Vendor Feed", "description" => "Wait for the vendor CSV every morning.", "path" => "incoming/vendor_a", "source" => "*.csv", "exclude_pattern" => "*.tmp", "disabled" => true, "expectations_version" => 1, "trigger" => "manual", "interval" => "day", "recurring_day" => 3, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:00" ], "schedule_time_zone" => "UTC", "holiday_region" => "us", "lookback_interval" => 3600, "late_acceptance_interval" => 900, "inactivity_interval" => 300, "max_open_interval" => 43200, "criteria" => { "count" => { "exact" => 1 }, "extensions" => [ "csv" ] }, "last_evaluated_at" => "2000-01-01T01:00:00Z", "last_success_at" => "2000-01-01T01:00:00Z", "last_failure_at" => "2000-01-01T01:00:00Z", "last_result" => "success", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :name, type: String
      optional :description, type: String
      optional :path, type: String
      optional :source, type: String
      optional :exclude_pattern, type: String
      optional :disabled, type: Boolean
      optional :trigger, type: String
      optional :interval, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
      optional :lookback_interval, type: Integer
      optional :late_acceptance_interval, type: Integer
      optional :inactivity_interval, type: Integer
      optional :max_open_interval, type: Integer
      optional :criteria, type: Hash
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/expectations" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Daily Vendor Feed", "description" => "Wait for the vendor CSV every morning.", "path" => "incoming/vendor_a", "source" => "*.csv", "exclude_pattern" => "*.tmp", "disabled" => true, "expectations_version" => 1, "trigger" => "manual", "interval" => "day", "recurring_day" => 3, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:00" ], "schedule_time_zone" => "UTC", "holiday_region" => "us", "lookback_interval" => 3600, "late_acceptance_interval" => 900, "inactivity_interval" => 300, "max_open_interval" => 43200, "criteria" => { "count" => { "exact" => 1 }, "extensions" => [ "csv" ] }, "last_evaluated_at" => "2000-01-01T01:00:00Z", "last_success_at" => "2000-01-01T01:00:00Z", "last_failure_at" => "2000-01-01T01:00:00Z", "last_result" => "success", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/expectations/:id/trigger" do
      status 201
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_via" => "manual", "opened_at" => "2000-01-01T01:00:00Z", "window_start_at" => "2000-01-01T01:00:00Z", "window_end_at" => "2000-01-01T01:00:00Z", "deadline_at" => "2000-01-01T01:00:00Z", "late_acceptance_cutoff_at" => "2000-01-01T01:00:00Z", "hard_close_at" => "2000-01-01T01:00:00Z", "closed_at" => "2000-01-01T01:00:00Z", "matched_files" => [], "missing_files" => [], "criteria_errors" => [], "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :description, type: String
      optional :path, type: String
      optional :source, type: String
      optional :exclude_pattern, type: String
      optional :disabled, type: Boolean
      optional :trigger, type: String
      optional :interval, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
      optional :lookback_interval, type: Integer
      optional :late_acceptance_interval, type: Integer
      optional :inactivity_interval, type: Integer
      optional :max_open_interval, type: Integer
      optional :criteria, type: Hash
      optional :workspace_id, type: Integer
    end
    patch "/api/rest/v1/expectations/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Daily Vendor Feed", "description" => "Wait for the vendor CSV every morning.", "path" => "incoming/vendor_a", "source" => "*.csv", "exclude_pattern" => "*.tmp", "disabled" => true, "expectations_version" => 1, "trigger" => "manual", "interval" => "day", "recurring_day" => 3, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:00" ], "schedule_time_zone" => "UTC", "holiday_region" => "us", "lookback_interval" => 3600, "late_acceptance_interval" => 900, "inactivity_interval" => 300, "max_open_interval" => 43200, "criteria" => { "count" => { "exact" => 1 }, "extensions" => [ "csv" ] }, "last_evaluated_at" => "2000-01-01T01:00:00Z", "last_success_at" => "2000-01-01T01:00:00Z", "last_failure_at" => "2000-01-01T01:00:00Z", "last_result" => "success", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/expectations/:id" do
      status 204
      body false
    end
  end
end
