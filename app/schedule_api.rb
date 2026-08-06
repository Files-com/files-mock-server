module FilesMockServer
  class ScheduleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/schedules" do
      status 200
      [ { "id" => 1, "name" => "Weekday overnight", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "01:00" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Triggered every Monday, Tuesday, Wednesday, Thursday, Friday at 01:00 AM UTC TZ.", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :name, type: String
      requires :schedule_days_of_week, type: [ Integer ]
      requires :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
    end
    post "/api/rest/v1/schedules" do
      status 201
      { "id" => 1, "name" => "Weekday overnight", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "01:00" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Triggered every Monday, Tuesday, Wednesday, Thursday, Friday at 01:00 AM UTC TZ.", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/schedules/:id" do
      status 200
      { "id" => 1, "name" => "Weekday overnight", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "01:00" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Triggered every Monday, Tuesday, Wednesday, Thursday, Friday at 01:00 AM UTC TZ.", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_times_of_day, type: [ String ]
      optional :schedule_time_zone, type: String
      optional :holiday_region, type: String
    end
    patch "/api/rest/v1/schedules/:id" do
      status 200
      { "id" => 1, "name" => "Weekday overnight", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "01:00" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Triggered every Monday, Tuesday, Wednesday, Thursday, Friday at 01:00 AM UTC TZ.", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/schedules/:id" do
      status 204
      body false
    end
  end
end
