module FilesMockServer
  class MonitoringStatAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/monitoring_stats" do
      status 200
      [ { "alerts" => [ "example" ], "info" => "example" } ]
    end

    post "/api/rest/v1/monitoring_stats/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
