module FilesMockServer
  class BundleAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
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
      [ { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "require_share_recipient" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "has_inbox" => true, "paths" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "require_share_recipient" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "has_inbox" => true, "paths" => [] }
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
      optional :require_share_recipient, type: Boolean
    end
    post "/api/rest/v1/bundles" do
      status 201
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "require_share_recipient" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "has_inbox" => true, "paths" => [] }
    end

    params do
      requires :id, type: Integer
      requires :to, type: Array[String]
      optional :note, type: String
      optional :recipients, type: Array[Hash]
    end
    post "/api/rest/v1/bundles/:id/share" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :password, type: String
      optional :clickwrap_id, type: Integer
      optional :code, type: String
      optional :description, type: String
      optional :expires_at, type: String
      optional :inbox_id, type: Integer
      optional :max_uses, type: Integer
      optional :note, type: String
      optional :require_registration, type: Boolean
      optional :require_share_recipient, type: Boolean
    end
    patch "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "password_protected" => true, "require_registration" => true, "require_share_recipient" => true, "clickwrap_body" => "[Legal text]", "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "expires_at" => "2000-01-01T01:00:00Z", "max_uses" => 1, "note" => "The internal note on the bundle.", "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "has_inbox" => true, "paths" => [] }
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
