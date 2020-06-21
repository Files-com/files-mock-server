module FilesMockServer
  class ProjectAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/projects" do
      status 200
      [{"id"=>1, "global_access"=>"none"}]
    end

    params do
      requires :id, type: Integer
    end
    get "/projects/:id" do
      status 200
      {"id"=>1, "global_access"=>"none"}
    end

    params do
      requires :global_access, type: String
    end
    post "/projects" do
      status 201
      {"id"=>1, "global_access"=>"none"}
    end

    params do
      requires :id, type: Integer
      requires :global_access, type: String
    end
    patch "/projects/:id" do
      status 200
      {"id"=>1, "global_access"=>"none"}
    end

    params do
      requires :id, type: Integer
    end
    delete "/projects/:id" do
      status 204
      body false
    end
  end
end
