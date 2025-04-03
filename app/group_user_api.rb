module FilesMockServer
  class GroupUserAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :group_id, type: Integer
    end
    get "/api/rest/v1/group_users" do
      status 200
      [ { "group_name" => "My Group", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" } ]
    end

    params do
      requires :group_id, type: Integer
      requires :user_id, type: Integer
      optional :admin, type: Boolean
    end
    post "/api/rest/v1/group_users" do
      status 201
      { "group_name" => "My Group", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" }
    end

    params do
      requires :id, type: Integer
      requires :group_id, type: Integer
      requires :user_id, type: Integer
      optional :admin, type: Boolean
    end
    patch "/api/rest/v1/group_users/:id" do
      status 200
      { "group_name" => "My Group", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" }
    end

    params do
      requires :id, type: Integer
      requires :group_id, type: Integer
      requires :user_id, type: Integer
    end
    delete "/api/rest/v1/group_users/:id" do
      status 204
      body false
    end
  end
end
