module FilesMockServer
  class PreviewAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :ids, type: String
      optional :bundle_registration_code, type: String
      optional :size, type: String
    end
    get "/api/rest/v1/previews" do
      status 200
      [ { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } ]
    end

    params do
      requires :id, type: Integer
      optional :bundle_registration_code, type: String
      optional :size, type: String
    end
    get "/api/rest/v1/previews/:id" do
      status 200
      { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" }
    end

    params do
      requires :ids, type: String
      optional :bundle_registration_code, type: String
      optional :size, type: String
    end
    post "/api/rest/v1/previews/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
