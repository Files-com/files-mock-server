module FilesMockServer
  class ApplicationConnectionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/application_connections" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "example", "application_key" => "example", "origin" => "example", "secret_id" => 1, "authentication" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :name, type: String
      optional :secret_id, type: Integer
      requires :application_key, type: String
      requires :origin, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/application_connections" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "example", "application_key" => "example", "origin" => "example", "secret_id" => 1, "authentication" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/application_connections/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "example", "application_key" => "example", "origin" => "example", "secret_id" => 1, "authentication" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :secret_id, type: Integer
    end
    patch "/api/rest/v1/application_connections/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "example", "application_key" => "example", "origin" => "example", "secret_id" => 1, "authentication" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/application_connections/:id" do
      status 204
      body false
    end
  end
end
