module FilesMockServer
  class BundleAPI < Grape::API
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
    get "/api/rest/v1/bundles" do
      status 200
      [ { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "paths" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "paths" => [] }
    end

    params do
      optional :user_id, type: Integer
      requires :paths, type: Array[String]
      optional :password, type: String
      optional :expires_at, type: String
      optional :max_uses, type: Integer
      optional :description, type: String
      optional :note, type: String
      optional :code, type: String
      optional :require_registration, type: Boolean
      optional :clickwrap_id, type: Integer
      optional :inbox_id, type: Integer
    end
    post "/api/rest/v1/bundles" do
      status 201
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "paths" => [] }
    end

    params do
      requires :id, type: Integer
      requires :to, type: Array[String]
      optional :note, type: String
    end
    post "/api/rest/v1/bundles/:id/share" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :password, type: String
      optional :expires_at, type: String
      optional :max_uses, type: Integer
      optional :description, type: String
      optional :note, type: String
      optional :code, type: String
      optional :require_registration, type: Boolean
      optional :clickwrap_id, type: Integer
      optional :inbox_id, type: Integer
    end
    patch "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "paths" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/bundles/:id" do
      status 204
      body false
    end
  end
end
