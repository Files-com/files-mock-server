module FilesMockServer
  class ZipDownloadAPI < Grape::API
    format :json

    params do
      requires :paths, type: [ String ]
      optional :bundle_registration_code, type: String
      optional :encoded_paths, type: [ String ]
    end
    post "/api/rest/v1/zip_downloads" do
      status 201
      { "download_uri" => "/zip/download?z=CODE" }
    end
  end
end
