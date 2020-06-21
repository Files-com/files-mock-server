module FilesMockServer
  class BundleAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/bundles" do
      status 200
      [{"code"=>"abc123", "url"=>"https://subdomain.files.com/f/12345678", "description"=>"The public description of the bundle.", "password_protected"=>true, "require_registration"=>true, "id"=>1, "created_at"=>"2000-01-01T01:00:00Z", "expires_at"=>"2000-01-01T01:00:00Z", "note"=>"The internal note on the bundle.", "user_id"=>1, "username"=>"user", "paths"=>[]}]
    end

    params do
      requires :id, type: Integer
    end
    get "/bundles/:id" do
      status 200
      {"code"=>"abc123", "url"=>"https://subdomain.files.com/f/12345678", "description"=>"The public description of the bundle.", "password_protected"=>true, "require_registration"=>true, "id"=>1, "created_at"=>"2000-01-01T01:00:00Z", "expires_at"=>"2000-01-01T01:00:00Z", "note"=>"The internal note on the bundle.", "user_id"=>1, "username"=>"user", "paths"=>[]}
    end

    params do
      optional :user_id, type: Integer
      requires :paths, type: Array[String]
      optional :password, type: String
      optional :expires_at, type: String
      optional :description, type: String
      optional :note, type: String
      optional :code, type: String
      optional :require_registration, type: Boolean
    end
    post "/bundles" do
      status 201
      {"code"=>"abc123", "url"=>"https://subdomain.files.com/f/12345678", "description"=>"The public description of the bundle.", "password_protected"=>true, "require_registration"=>true, "id"=>1, "created_at"=>"2000-01-01T01:00:00Z", "expires_at"=>"2000-01-01T01:00:00Z", "note"=>"The internal note on the bundle.", "user_id"=>1, "username"=>"user", "paths"=>[]}
    end

    params do
      requires :id, type: Integer
      requires :to, type: Array[String]
      optional :note, type: String
    end
    post "/bundles/:id/share" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :password, type: String
      optional :expires_at, type: String
      optional :description, type: String
      optional :note, type: String
      optional :code, type: String
      optional :require_registration, type: Boolean
    end
    patch "/bundles/:id" do
      status 200
      {"code"=>"abc123", "url"=>"https://subdomain.files.com/f/12345678", "description"=>"The public description of the bundle.", "password_protected"=>true, "require_registration"=>true, "id"=>1, "created_at"=>"2000-01-01T01:00:00Z", "expires_at"=>"2000-01-01T01:00:00Z", "note"=>"The internal note on the bundle.", "user_id"=>1, "username"=>"user", "paths"=>[]}
    end

    params do
      requires :id, type: Integer
    end
    delete "/bundles/:id" do
      status 204
      body false
    end
  end
end
