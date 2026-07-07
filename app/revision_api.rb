module FilesMockServer
  class RevisionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/revisions" do
      status 200
      [ { "current" => "a1b2c3d4", "prior" => "f9e8d7c6", "revision" => "a1b2c3d4", "up_to_date" => true } ]
    end

    post "/api/rest/v1/revisions/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
