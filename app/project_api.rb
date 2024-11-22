module FilesMockServer
  class ProjectAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/projects" do
      status 200
      [ { "id" => 1, "global_access" => "none" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/projects/:id" do
      status 200
      { "id" => 1, "global_access" => "none" }
    end

    params do
      requires :global_access, type: String
    end
    post "/api/rest/v1/projects" do
      status 201
      { "id" => 1, "global_access" => "none" }
    end

    post "/api/rest/v1/projects/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      requires :global_access, type: String
    end
    patch "/api/rest/v1/projects/:id" do
      status 200
      { "id" => 1, "global_access" => "none" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/projects/:id" do
      status 204
      body false
    end
  end
end
