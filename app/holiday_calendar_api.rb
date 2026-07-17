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
      [ { "id" => 1, "name" => "Company Holidays", "definition" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :name, type: String
    end
    post "/api/rest/v1/holiday_calendars" do
      status 201
      { "id" => 1, "name" => "Company Holidays", "definition" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/holiday_calendars/:id" do
      status 200
      { "id" => 1, "name" => "Company Holidays", "definition" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
    end
    patch "/api/rest/v1/holiday_calendars/:id" do
      status 200
      { "id" => 1, "name" => "Company Holidays", "definition" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
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
