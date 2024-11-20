module FilesMockServer
  class PermissionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
      optional :path, type: String
      optional :include_groups, type: Boolean
      optional :group_id, type: String
      optional :user_id, type: String
    end
    get "/api/rest/v1/permissions" do
      status 200
      [ { "id" => 1, "path" => "example", "user_id" => 1, "username" => "user", "group_id" => 1, "group_name" => "example", "permission" => "full", "recursive" => true } ]
    end

    params do
      requires :path, type: String
      optional :group_id, type: Integer
      optional :permission, type: String
      optional :recursive, type: Boolean
      optional :user_id, type: Integer
      optional :username, type: String
      optional :group_name, type: String
    end
    post "/api/rest/v1/permissions" do
      status 201
      { "id" => 1, "path" => "example", "user_id" => 1, "username" => "user", "group_id" => 1, "group_name" => "example", "permission" => "full", "recursive" => true }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
      optional :path, type: String
      optional :include_groups, type: Boolean
      optional :group_id, type: String
      optional :user_id, type: String
    end
    post "/api/rest/v1/permissions/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/permissions/:id" do
      status 204
      body false
    end
  end
end
