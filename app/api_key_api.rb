module FilesMockServer
  class ApiKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/api_keys" do
      status 200
      [ { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 } ]
    end

    params do
      optional :format, type: String
      optional :api_key, type: Hash
    end
    get "/api/rest/v1/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      optional :user_id, type: Integer
      optional :name, type: String
      optional :expires_at, type: String
      optional :permission_set, type: String
      optional :path, type: String
    end
    post "/api/rest/v1/api_keys" do
      status 201
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      optional :expires_at, type: String
      optional :name, type: String
      optional :permission_set, type: String
    end
    patch "/api/rest/v1/api_key" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :expires_at, type: String
      optional :permission_set, type: String
    end
    patch "/api/rest/v1/api_keys/:id" do
      status 200
      { "id" => 1, "descriptive_label" => "Site-wide API key for https://site.files.com/ (key ID #1)", "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "key" => "[key]", "last_use_at" => "2000-01-01T01:00:00Z", "name" => "My Main API Key", "path" => "shared/docs", "permission_set" => "full", "platform" => "win32", "user_id" => 1 }
    end

    params do
      optional :format, type: String
      optional :api_key, type: Hash
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
