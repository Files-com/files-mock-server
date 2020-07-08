module FilesMockServer
  class BundleDownloadAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      requires :bundle_registration_id, type: Integer
    end
    get "/api/rest/v1/bundle_downloads" do
      status 200
      [ { "download_method" => "file", "path" => "a/b/test.txt", "created_at" => "2020-01-01 00:00:00" } ]
    end
  end
end
