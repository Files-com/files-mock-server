module FilesMockServer
  class ClickwrapAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
    end
    get "/api/rest/v1/clickwraps" do
      status 200
      [ { "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "", "use_with_bundles" => "", "use_with_inboxes" => "" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/clickwraps/:id" do
      status 200
      { "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "", "use_with_bundles" => "", "use_with_inboxes" => "" }
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
      { "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "", "use_with_bundles" => "", "use_with_inboxes" => "" }
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
      { "name" => "Example Site NDA for Files.com Use", "body" => "[Legal body text]", "use_with_users" => "", "use_with_bundles" => "", "use_with_inboxes" => "" }
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
