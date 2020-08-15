module FilesMockServer
  class PublicKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
    end
    get "/api/rest/v1/public_keys" do
      status 200
      [ { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/public_keys/:id" do
      status 200
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8" }
    end

    params do
      optional :user_id, type: Integer
      requires :title, type: String
      requires :public_key, type: String
    end
    post "/api/rest/v1/public_keys" do
      status 201
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8" }
    end

    params do
      requires :id, type: Integer
      requires :title, type: String
    end
    patch "/api/rest/v1/public_keys/:id" do
      status 200
      { "id" => 1, "title" => "My public key", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8" }
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
