module FilesMockServer
  class KeyLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/key_lifecycle_rules" do
      status 200
      [ { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "name" => "inactive gpg keys" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/key_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "name" => "inactive gpg keys" }
    end

    params do
      optional :key_type, type: String
      optional :inactivity_days, type: Integer
      optional :name, type: String
    end
    post "/api/rest/v1/key_lifecycle_rules" do
      status 201
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "name" => "inactive gpg keys" }
    end

    params do
      requires :id, type: Integer
      optional :key_type, type: String
      optional :inactivity_days, type: Integer
      optional :name, type: String
    end
    patch "/api/rest/v1/key_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "name" => "inactive gpg keys" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/key_lifecycle_rules/:id" do
      status 204
      body false
    end
  end
end
