module FilesMockServer
  class UserLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules" do
      status 200
      [ { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "site_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "site_id" => 1 }
    end

    params do
      requires :action, type: String
      requires :authentication_method, type: String
      requires :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
    end
    post "/api/rest/v1/user_lifecycle_rules" do
      status 201
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "site_id" => 1 }
    end

    params do
      requires :id, type: Integer
      requires :action, type: String
      requires :authentication_method, type: String
      requires :inactivity_days, type: Integer
      optional :include_site_admins, type: Boolean
      optional :include_folder_admins, type: Boolean
    end
    patch "/api/rest/v1/user_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "inactivity_days" => 12, "include_folder_admins" => true, "include_site_admins" => true, "action" => "disable", "site_id" => 1 }
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
