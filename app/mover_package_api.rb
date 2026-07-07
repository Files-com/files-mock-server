module FilesMockServer
  class MoverPackageAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/mover_packages" do
      status 200
      [ { "id" => 1, "prepaid_bytes" => 1, "prepaid_expire_in_days" => 1, "price" => "1.0" } ]
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/mover_packages/:id/purchase" do
      status 201
      { "id" => 1, "prepaid_bytes" => 1, "prepaid_expire_in_days" => 1, "price" => "1.0" }
    end

    post "/api/rest/v1/mover_packages/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
