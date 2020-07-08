module FilesMockServer
  class GroupAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :ids, type: String
    end
    get "/api/rest/v1/groups" do
      status 200
      [ { "id" => 1, "name" => "owners", "admin_ids" => [], "notes" => "", "user_ids" => [], "usernames" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "admin_ids" => [], "notes" => "", "user_ids" => [], "usernames" => [] }
    end

    params do
      optional :name, type: String
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
    end
    post "/api/rest/v1/groups" do
      status 201
      { "id" => 1, "name" => "owners", "admin_ids" => [], "notes" => "", "user_ids" => [], "usernames" => [] }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
    end
    patch "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "admin_ids" => [], "notes" => "", "user_ids" => [], "usernames" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/groups/:id" do
      status 204
      body false
    end
  end
end
