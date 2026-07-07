module FilesMockServer
  class ScheduledExportAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/scheduled_exports" do
      status 200
      [ { "id" => 1, "name" => "Monthly access review", "export_type" => "permission_audit", "report_name" => "Permission audit", "export_options" => { "group_by" => "user" }, "user_id" => 1, "disabled" => true, "trigger" => "daily", "interval" => "month", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every month at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "last_export_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/scheduled_exports/:id" do
      status 200
      { "id" => 1, "name" => "Monthly access review", "export_type" => "permission_audit", "report_name" => "Permission audit", "export_options" => { "group_by" => "user" }, "user_id" => 1, "disabled" => true, "trigger" => "daily", "interval" => "month", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every month at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "last_export_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :name, type: String
      requires :export_type, type: String
      optional :export_options, type: Hash
      optional :user_id, type: Integer
      optional :disabled, type: Boolean
      optional :trigger, type: String
      optional :interval, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
    end
    post "/api/rest/v1/scheduled_exports" do
      status 201
      { "id" => 1, "name" => "Monthly access review", "export_type" => "permission_audit", "report_name" => "Permission audit", "export_options" => { "group_by" => "user" }, "user_id" => 1, "disabled" => true, "trigger" => "daily", "interval" => "month", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every month at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "last_export_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/scheduled_exports/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :export_type, type: String
      optional :export_options, type: Hash
      optional :user_id, type: Integer
      optional :disabled, type: Boolean
      optional :trigger, type: String
      optional :interval, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
    end
    patch "/api/rest/v1/scheduled_exports/:id" do
      status 200
      { "id" => 1, "name" => "Monthly access review", "export_type" => "permission_audit", "report_name" => "Permission audit", "export_options" => { "group_by" => "user" }, "user_id" => 1, "disabled" => true, "trigger" => "daily", "interval" => "month", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every month at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "last_export_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/scheduled_exports/:id" do
      status 204
      body false
    end
  end
end
