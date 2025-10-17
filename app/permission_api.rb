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
      optional :partner_id, type: String
      optional :user_id, type: String
    end
    get "/api/rest/v1/permissions" do
      status 200
      [ { "id" => 1, "path" => "example", "user_id" => 1, "username" => "user", "group_id" => 1, "group_name" => "example", "partner_id" => 1, "partner_name" => "Acme Corp.", "permission" => "full", "recursive" => true, "site_id" => 1 } ]
    end

    params do
      requires :path, type: String
      optional :group_id, type: Integer
      optional :permission, type: String
      optional :recursive, type: Boolean
      optional :partner_id, type: Integer
      optional :user_id, type: Integer
      optional :username, type: String
      optional :group_name, type: String
      optional :site_id, type: Integer
    end
    post "/api/rest/v1/permissions" do
      status 201
      { "id" => 1, "path" => "example", "user_id" => 1, "username" => "user", "group_id" => 1, "group_name" => "example", "partner_id" => 1, "partner_name" => "Acme Corp.", "permission" => "full", "recursive" => true, "site_id" => 1 }
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
