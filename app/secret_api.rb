module FilesMockServer
  class SecretAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/secrets" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Production API token", "description" => "Used by production API integrations.", "secret_type" => "token", "metadata" => { "key" => "example value" }, "value_field_names" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/secrets/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Production API token", "description" => "Used by production API integrations.", "secret_type" => "token", "metadata" => { "key" => "example value" }, "value_field_names" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :name, type: String
      optional :description, type: String
      requires :secret_type, type: String
      optional :metadata, type: Hash
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/secrets" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Production API token", "description" => "Used by production API integrations.", "secret_type" => "token", "metadata" => { "key" => "example value" }, "value_field_names" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :description, type: String
      optional :secret_type, type: String
      optional :metadata, type: Hash
    end
    patch "/api/rest/v1/secrets/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Production API token", "description" => "Used by production API integrations.", "secret_type" => "token", "metadata" => { "key" => "example value" }, "value_field_names" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/secrets/:id" do
      status 204
      body false
    end
  end
end
