module FilesMockServer
  class DatabaseDestinationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/database_destinations" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Orders", "provider" => "snowflake", "config" => "example", "secret_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :name, type: String
      requires :provider, type: String
      requires :config, type: Hash
      requires :secret_id, type: Integer
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/database_destinations" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Orders", "provider" => "snowflake", "config" => "example", "secret_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/database_destinations/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Orders", "provider" => "snowflake", "config" => "example", "secret_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :secret_id, type: Integer
      optional :config, type: Hash
    end
    patch "/api/rest/v1/database_destinations/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Orders", "provider" => "snowflake", "config" => "example", "secret_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/database_destinations/:id" do
      status 204
      body false
    end
  end
end
