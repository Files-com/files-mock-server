module FilesMockServer
  class ChildSiteManagementPolicyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies" do
      status 200
      [ { "id" => 1, "site_id" => 1, "site_setting_name" => "color2_left", "managed_value" => "#FF0000", "skip_child_site_ids" => [ 1, 5 ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "site_id" => 1, "site_setting_name" => "color2_left", "managed_value" => "#FF0000", "skip_child_site_ids" => [ 1, 5 ] }
    end

    params do
      requires :site_setting_name, type: String
      requires :managed_value, type: String
      optional :skip_child_site_ids, type: [ Integer ]
    end
    post "/api/rest/v1/child_site_management_policies" do
      status 201
      { "id" => 1, "site_id" => 1, "site_setting_name" => "color2_left", "managed_value" => "#FF0000", "skip_child_site_ids" => [ 1, 5 ] }
    end

    params do
      requires :id, type: Integer
      requires :site_setting_name, type: String
      requires :managed_value, type: String
      optional :skip_child_site_ids, type: [ Integer ]
    end
    patch "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "site_id" => 1, "site_setting_name" => "color2_left", "managed_value" => "#FF0000", "skip_child_site_ids" => [ 1, 5 ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/child_site_management_policies/:id" do
      status 204
      body false
    end
  end
end
