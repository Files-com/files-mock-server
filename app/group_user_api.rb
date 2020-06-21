module FilesMockServer
  class GroupUserAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :group_id, type: Integer
    end
    get "/group_users" do
      status 200
      [ { "group_name" => "My Group", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => [] } ]
    end

    params do
      requires :id, type: Integer
      requires :group_id, type: Integer
      requires :user_id, type: Integer
      optional :admin, type: Boolean
    end
    patch "/group_users/:id" do
      status 200
      { "group_name" => "My Group", "group_id" => 1, "user_id" => 1, "admin" => true, "usernames" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/group_users/:id" do
      status 204
      body false
    end
  end
end
