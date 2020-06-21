module FilesMockServer
  class ApiKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api_keys" do
      status 200
      [ { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 } ]
    end

    get "/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    get "/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      optional :user_id, type: Integer
      optional :name, type: String
      optional :permission_set, type: String
      optional :expires_at, type: String
    end
    post "/api_keys" do
      status 201
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      optional :name, type: String
      optional :permission_set, type: String
      optional :expires_at, type: String
    end
    patch "/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :permission_set, type: String
      optional :expires_at, type: String
    end
    patch "/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    delete "/api_key" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    delete "/api_keys/:id" do
      status 204
      body false
    end
  end
end
