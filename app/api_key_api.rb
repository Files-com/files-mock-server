module FilesMockServer
  class ApiKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/api_keys" do
      status 200
      [ { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 } ]
    end

    get "/api/rest/v1/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 }
    end

    params do
      optional :user_id, type: Integer
      optional :description, type: String
      optional :expires_at, type: String
      optional :permission_set, type: String
      requires :name, type: String
      optional :path, type: String
    end
    post "/api/rest/v1/api_keys" do
      status 201
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 }
    end

    params do
      optional :user_id, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    post "/api/rest/v1/api_keys/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :expires_at, type: String
      optional :name, type: String
      optional :permission_set, type: String
    end
    patch "/api/rest/v1/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :description, type: String
      optional :expires_at, type: String
      optional :permission_set, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "description" => "example", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "permission_set" => "full", "platform" => "win32", "url" => "example", "user_id" => 1 }
    end

    delete "/api/rest/v1/api_key" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/api_keys/:id" do
      status 204
      body false
    end
  end
end
