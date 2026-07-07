module FilesMockServer
  class ZipDownloadFileAPI < Grape::API
    format :json

    params do
      requires :code, type: String
      optional :limit, type: Integer
      optional :cursor, type: String
      optional :site_id, type: Integer
    end
    post "/api/rest/v1/zip_download_files" do
      status 201
      { "site_id" => 1, "user_id" => 1, "bundle_id" => 1, "bundle_registration_id" => 1, "files" => [ "example" ], "cursor" => "example" }
    end
  end
end
