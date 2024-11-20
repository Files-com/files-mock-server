module FilesMockServer
  class ClickwrapAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/clickwraps" do
      status 200
      [ { "id" => 1, "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "example", "use_with_bundles" => "example", "use_with_inboxes" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/clickwraps/:id" do
      status 200
      { "id" => 1, "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "example", "use_with_bundles" => "example", "use_with_inboxes" => "example" }
    end

    params do
      optional :name, type: String
      optional :body, type: String
      optional :use_with_bundles, type: String
      optional :use_with_inboxes, type: String
      optional :use_with_users, type: String
    end
    post "/api/rest/v1/clickwraps" do
      status 201
      { "id" => 1, "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "example", "use_with_bundles" => "example", "use_with_inboxes" => "example" }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    post "/api/rest/v1/clickwraps/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :body, type: String
      optional :use_with_bundles, type: String
      optional :use_with_inboxes, type: String
      optional :use_with_users, type: String
    end
    patch "/api/rest/v1/clickwraps/:id" do
      status 200
      { "id" => 1, "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "example", "use_with_bundles" => "example", "use_with_inboxes" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/clickwraps/:id" do
      status 204
      body false
    end
  end
end
