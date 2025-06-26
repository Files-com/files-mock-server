module FilesMockServer
  class HolidayRegionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/holiday_regions/supported" do
      status 200
      [ { "code" => "us_dc", "name" => "United States - District of Columbia" } ]
    end
  end
end
