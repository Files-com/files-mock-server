module FilesMockServer
  class ChildSiteManagementPolicyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies" do
      status 200
      [ { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\" }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\" }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :value, type: String
      optional :skip_child_site_ids, type: [ Integer ]
      requires :policy_type, type: String
      optional :name, type: String
      optional :description, type: String
    end
    post "/api/rest/v1/child_site_management_policies" do
      status 201
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\" }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: [ String, Integer, Hash ]
      optional :value, type: String
      optional :skip_child_site_ids, type: [ Integer ]
      optional :policy_type, type: String
      optional :name, type: String
      optional :description, type: [ String, Integer, Hash ]
    end
    patch "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\" }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
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
