module FilesMockServer
  class As2KeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api/rest/v1/as2_keys" do
      status 200
      [ { "id" => 1, "as2_partnership_name" => "Test", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "cf:cb:d3:26:52:6c:55:88:83:17:13:cf:e7:70:eb:1b:32:37:38:c0" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/as2_keys/:id" do
      status 200
      { "id" => 1, "as2_partnership_name" => "Test", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "cf:cb:d3:26:52:6c:55:88:83:17:13:cf:e7:70:eb:1b:32:37:38:c0" }
    end

    params do
      optional :user_id, type: Integer
      requires :as2_partnership_name, type: String
      requires :public_key, type: String
    end
    post "/api/rest/v1/as2_keys" do
      status 201
      { "id" => 1, "as2_partnership_name" => "Test", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "cf:cb:d3:26:52:6c:55:88:83:17:13:cf:e7:70:eb:1b:32:37:38:c0" }
    end

    params do
      requires :id, type: Integer
      requires :as2_partnership_name, type: String
    end
    patch "/api/rest/v1/as2_keys/:id" do
      status 200
      { "id" => 1, "as2_partnership_name" => "Test", "created_at" => "2000-01-01T01:00:00Z", "fingerprint" => "cf:cb:d3:26:52:6c:55:88:83:17:13:cf:e7:70:eb:1b:32:37:38:c0" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/as2_keys/:id" do
      status 204
      body false
    end
  end
end
