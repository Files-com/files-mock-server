module FilesMockServer
  class ExportAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/exports" do
      status 200
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "download_uri" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/exports/:id" do
      status 200
      { "id" => 1, "export_status" => "example", "export_type" => "example", "download_uri" => "example" }
    end
  end
end
