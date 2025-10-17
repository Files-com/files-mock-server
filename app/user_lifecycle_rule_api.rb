module FilesMockServer
  class UserLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/user_lifecycle_rules" do
      status 200
      [ { "id" => 1, "authentication_method" => "password", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "name" => "password specific rules", "partner_tag" => "guest", "site_id" => 1, "user_state" => "inactive", "user_tag" => "guest" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "name" => "password specific rules", "partner_tag" => "guest", "site_id" => 1, "user_state" => "inactive", "user_tag" => "guest" }
    end

    params do
      optional :action, type: String
      optional :authentication_method, type: String
      optional :group_ids, type: [ Integer ]
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :name, type: String
      optional :partner_tag, type: String
      optional :user_state, type: String
      optional :user_tag, type: String
    end
    post "/api/rest/v1/user_lifecycle_rules" do
      status 201
      { "id" => 1, "authentication_method" => "password", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "name" => "password specific rules", "partner_tag" => "guest", "site_id" => 1, "user_state" => "inactive", "user_tag" => "guest" }
    end

    params do
      requires :id, type: Integer
      optional :action, type: String
      optional :authentication_method, type: String
      optional :group_ids, type: [ Integer ]
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :name, type: String
      optional :partner_tag, type: String
      optional :user_state, type: String
      optional :user_tag, type: String
    end
    patch "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "group_ids" => [ 1, 2, 3 ], "action" => "disable", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "name" => "password specific rules", "partner_tag" => "guest", "site_id" => 1, "user_state" => "inactive", "user_tag" => "guest" }
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
