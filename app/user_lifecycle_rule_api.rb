module FilesMockServer
  class UserLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/user_lifecycle_rules" do
      status 200
      [ { "id" => 1, "authentication_method" => "all_non_sso", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "apply_to_all_workspaces" => true, "name" => "password specific rules", "notify_users" => true, "partner_tag" => "guest", "site_id" => 1, "workspace_id" => 12, "user_state" => "inactive", "user_tag" => "guest" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "all_non_sso", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "apply_to_all_workspaces" => true, "name" => "password specific rules", "notify_users" => true, "partner_tag" => "guest", "site_id" => 1, "workspace_id" => 12, "user_state" => "inactive", "user_tag" => "guest" }
    end

    params do
      optional :action, type: String
      optional :apply_to_all_workspaces, type: Boolean
      optional :authentication_method, type: String
      optional :group_ids, type: [ Integer ]
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :name, type: String
      optional :notify_users, type: Boolean
      optional :partner_tag, type: String
      optional :user_state, type: String
      optional :user_tag, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/user_lifecycle_rules" do
      status 201
      { "id" => 1, "authentication_method" => "all_non_sso", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "apply_to_all_workspaces" => true, "name" => "password specific rules", "notify_users" => true, "partner_tag" => "guest", "site_id" => 1, "workspace_id" => 12, "user_state" => "inactive", "user_tag" => "guest" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/user_lifecycle_rules/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :action, type: String
      optional :apply_to_all_workspaces, type: Boolean
      optional :authentication_method, type: String
      optional :group_ids, type: [ Integer ]
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :name, type: String
      optional :notify_users, type: Boolean
      optional :partner_tag, type: String
      optional :user_state, type: String
      optional :user_tag, type: String
      optional :workspace_id, type: Integer
    end
    patch "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "all_non_sso", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "apply_to_all_workspaces" => true, "name" => "password specific rules", "notify_users" => true, "partner_tag" => "guest", "site_id" => 1, "workspace_id" => 12, "user_state" => "inactive", "user_tag" => "guest" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/user_lifecycle_rules/:id" do
      status 204
      body false
    end
  end
end
