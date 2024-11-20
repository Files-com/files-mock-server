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
      [ { "group_name" => "example", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" } ]
    end

    params do
      requires :group_id, type: Integer
      requires :user_id, type: Integer
      optional :admin, type: Boolean
    end
    post "/api/rest/v1/group_users" do
      status 201
      { "group_name" => "example", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" }
    end

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :group_id, type: Integer
    end
    post "/api/rest/v1/group_users/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
      requires :group_id, type: Integer
      requires :user_id, type: Integer
      optional :admin, type: Boolean
    end
    patch "/api/rest/v1/group_users/:id" do
      status 200
      { "group_name" => "example", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => "user" }
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
