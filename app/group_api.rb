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
      optional :include_parent_site_groups, type: Boolean
    end
    get "/api/rest/v1/groups" do
      status 200
      [ { "id" => 1, "name" => "owners", "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "user", "ftp_permission" => true, "sftp_permission" => true, "dav_permission" => true, "restapi_permission" => true, "site_id" => 1, "workspace_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "user", "ftp_permission" => true, "sftp_permission" => true, "dav_permission" => true, "restapi_permission" => true, "site_id" => 1, "workspace_id" => 1 }
    end

    params do
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
      optional :workspace_id, type: Integer
      optional :ftp_permission, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :dav_permission, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :allowed_ips, type: String
      requires :name, type: String
    end
    post "/api/rest/v1/groups" do
      status 201
      { "id" => 1, "name" => "owners", "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "user", "ftp_permission" => true, "sftp_permission" => true, "dav_permission" => true, "restapi_permission" => true, "site_id" => 1, "workspace_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :notes, type: String
      optional :user_ids, type: String
      optional :admin_ids, type: String
      optional :workspace_id, type: Integer
      optional :ftp_permission, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :dav_permission, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :allowed_ips, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/groups/:id" do
      status 200
      { "id" => 1, "name" => "owners", "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "admin_ids" => "1", "notes" => "example", "user_ids" => "1", "usernames" => "user", "ftp_permission" => true, "sftp_permission" => true, "dav_permission" => true, "restapi_permission" => true, "site_id" => 1, "workspace_id" => 1 }
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
