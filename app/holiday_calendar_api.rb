module FilesMockServer
  class HolidayCalendarAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/holiday_calendars" do
      status 200
      [ { "id" => 1, "name" => "Company Holidays", "definition" => { "months" => { "0" => [ { "name" => "Good Friday", "function" => "easter(year)", "function_modifier" => -2 } ], "1" => [ { "name" => "New Year's Day", "mday" => 1, "observed" => "to_weekday_if_weekend(date)" }, { "name" => "Third Monday", "week" => 3, "wday" => 1 } ], "11" => [ { "name" => "Thanksgiving", "week" => 4, "wday" => 4 } ], "12" => [ { "name" => "Christmas Eve Early Close", "mday" => 24, "start_time" => "13:00", "end_time" => "17:00", "year_ranges" => { "from" => 2026 } } ] } }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :definition, type: Hash
      requires :name, type: String
    end
    post "/api/rest/v1/holiday_calendars" do
      status 201
      { "id" => 1, "name" => "Company Holidays", "definition" => { "months" => { "0" => [ { "name" => "Good Friday", "function" => "easter(year)", "function_modifier" => -2 } ], "1" => [ { "name" => "New Year's Day", "mday" => 1, "observed" => "to_weekday_if_weekend(date)" }, { "name" => "Third Monday", "week" => 3, "wday" => 1 } ], "11" => [ { "name" => "Thanksgiving", "week" => 4, "wday" => 4 } ], "12" => [ { "name" => "Christmas Eve Early Close", "mday" => 24, "start_time" => "13:00", "end_time" => "17:00", "year_ranges" => { "from" => 2026 } } ] } }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/holiday_calendars/:id" do
      status 200
      { "id" => 1, "name" => "Company Holidays", "definition" => { "months" => { "0" => [ { "name" => "Good Friday", "function" => "easter(year)", "function_modifier" => -2 } ], "1" => [ { "name" => "New Year's Day", "mday" => 1, "observed" => "to_weekday_if_weekend(date)" }, { "name" => "Third Monday", "week" => 3, "wday" => 1 } ], "11" => [ { "name" => "Thanksgiving", "week" => 4, "wday" => 4 } ], "12" => [ { "name" => "Christmas Eve Early Close", "mday" => 24, "start_time" => "13:00", "end_time" => "17:00", "year_ranges" => { "from" => 2026 } } ] } }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :definition, type: Hash
      optional :name, type: String
    end
    patch "/api/rest/v1/holiday_calendars/:id" do
      status 200
      { "id" => 1, "name" => "Company Holidays", "definition" => { "months" => { "0" => [ { "name" => "Good Friday", "function" => "easter(year)", "function_modifier" => -2 } ], "1" => [ { "name" => "New Year's Day", "mday" => 1, "observed" => "to_weekday_if_weekend(date)" }, { "name" => "Third Monday", "week" => 3, "wday" => 1 } ], "11" => [ { "name" => "Thanksgiving", "week" => 4, "wday" => 4 } ], "12" => [ { "name" => "Christmas Eve Early Close", "mday" => 24, "start_time" => "13:00", "end_time" => "17:00", "year_ranges" => { "from" => 2026 } } ] } }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/holiday_calendars/:id" do
      status 204
      body false
    end
  end
end
