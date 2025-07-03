module FilesMockServer
  class UserLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules" do
      status 200
      [ { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "user_state" => "inactive", "name" => "password specific rules", "site_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "user_state" => "inactive", "name" => "password specific rules", "site_id" => 1 }
    end

    params do
      optional :action, type: String
      optional :authentication_method, type: String
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :user_state, type: String
      optional :name, type: String
    end
    post "/api/rest/v1/user_lifecycle_rules" do
      status 201
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "user_state" => "inactive", "name" => "password specific rules", "site_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :action, type: String
      optional :authentication_method, type: String
      optional :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
      optional :user_state, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "user_state" => "inactive", "name" => "password specific rules", "site_id" => 1 }
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
