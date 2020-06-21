module FilesMockServer
  class PermissionAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :path, type: String
      optional :group_id, type: String
      optional :user_id, type: String
      optional :include_groups, type: Boolean
    end
    get "/permissions" do
      status 200
      [{"id"=>1, "path"=>"", "user_id"=>1, "username"=>"Sser", "group_id"=>1, "group_name"=>"", "permission"=>"full", "recursive"=>true}]
    end

    params do
      optional :group_id, type: Integer
      optional :path, type: String
      optional :permission, type: String
      optional :recursive, type: Boolean
      optional :user_id, type: Integer
      optional :username, type: String
    end
    post "/permissions" do
      status 201
      {"id"=>1, "path"=>"", "user_id"=>1, "username"=>"Sser", "group_id"=>1, "group_name"=>"", "permission"=>"full", "recursive"=>true}
    end

    params do
      requires :id, type: Integer
    end
    delete "/permissions/:id" do
      status 204
      body false
    end
  end
end
