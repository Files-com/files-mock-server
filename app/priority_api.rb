module FilesMockServer
  class PriorityAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :path, type: String
    end
    get "/api/rest/v1/priorities" do
      status 200
      [ { "path" => "foo/bar", "color" => "pink" } ]
    end

    params do
      requires :path, type: String
    end
    post "/api/rest/v1/priorities/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
