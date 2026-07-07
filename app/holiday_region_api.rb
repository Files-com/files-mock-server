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

    post "/api/rest/v1/holiday_regions/supported/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
