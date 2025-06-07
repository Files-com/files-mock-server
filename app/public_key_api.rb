module FilesMockServer
  class PublicKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/public_keys" do
      status 200
      [ { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8", "fingerprint_sha256" => "V5Q5t/ghT3R8Tol5GX9385bzmpygWVRnLuI9EXNrjCX", "last_login_at" => "2000-01-01T01:00:00Z", "username" => "User", "user_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/public_keys/:id" do
      status 200
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8", "fingerprint_sha256" => "V5Q5t/ghT3R8Tol5GX9385bzmpygWVRnLuI9EXNrjCX", "last_login_at" => "2000-01-01T01:00:00Z", "username" => "User", "user_id" => 1 }
    end

    params do
      optional :user_id, type: Integer
      requires :title, type: String
      requires :public_key, type: String
    end
    post "/api/rest/v1/public_keys" do
      status 201
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8", "fingerprint_sha256" => "V5Q5t/ghT3R8Tol5GX9385bzmpygWVRnLuI9EXNrjCX", "last_login_at" => "2000-01-01T01:00:00Z", "username" => "User", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
      requires :title, type: String
    end
    patch "/api/rest/v1/public_keys/:id" do
      status 200
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8", "fingerprint_sha256" => "V5Q5t/ghT3R8Tol5GX9385bzmpygWVRnLuI9EXNrjCX", "last_login_at" => "2000-01-01T01:00:00Z", "username" => "User", "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/public_keys/:id" do
      status 204
      body false
    end
  end
end
