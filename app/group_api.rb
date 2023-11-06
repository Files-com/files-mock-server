module FilesMockServer
  class GroupAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
      optional :ids, type: String
    end
    get "/api/rest/v1/groups" do
      status 200
      [ { "id" => 1, "name" => "owners", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "example" }
    end

    params do
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
      requires :name, type: String
    end
    post "/api/rest/v1/groups" do
      status 201
      { "id" => 1, "name" => "owners", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "example" }
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
