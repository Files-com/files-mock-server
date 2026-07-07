module FilesMockServer
  class WorkspaceAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/workspaces" do
      status 200
      [ { "id" => 1, "name" => "Project Alpha" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/workspaces/:id" do
      status 200
      { "id" => 1, "name" => "Project Alpha" }
    end

    params do
      optional :name, type: String
    end
    post "/api/rest/v1/workspaces" do
      status 201
      { "id" => 1, "name" => "Project Alpha" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
    end
    patch "/api/rest/v1/workspaces/:id" do
      status 200
      { "id" => 1, "name" => "Project Alpha" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/workspaces/:id" do
      status 204
      body false
    end
  end
end
