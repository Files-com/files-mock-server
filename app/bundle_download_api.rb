module FilesMockServer
  class BundleDownloadAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :bundle_id, type: Integer
      optional :bundle_registration_id, type: Integer
    end
    get "/api/rest/v1/bundle_downloads" do
      status 200
      [ { "bundle_registration" => "", "download_method" => "file", "path" => "a/b/test.txt", "created_at" => "2020-01-01 00:00:00" } ]
    end
  end
end
