module FilesMockServer
  class ChildSiteManagementPolicyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies" do
      status 200
      [ { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\", \"folder_behaviors\": [{ \"behavior\": \"file_expiration\", \"value\": { \"days_to_retain\": 30 } }] }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "child_site_ids" => [ 1, 2 ], "default_policy" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :value, type: Hash
      optional :skip_child_site_ids, type: [ Integer ]
      optional :child_site_ids, type: [ Integer ]
      optional :default_policy, type: Boolean
      requires :policy_type, type: String
      optional :name, type: String
      optional :description, type: String
    end
    post "/api/rest/v1/child_site_management_policies" do
      status 201
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\", \"folder_behaviors\": [{ \"behavior\": \"file_expiration\", \"value\": { \"days_to_retain\": 30 } }] }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "child_site_ids" => [ 1, 2 ], "default_policy" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\", \"folder_behaviors\": [{ \"behavior\": \"file_expiration\", \"value\": { \"days_to_retain\": 30 } }] }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "child_site_ids" => [ 1, 2 ], "default_policy" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :value, type: Hash
      optional :skip_child_site_ids, type: [ Integer ]
      optional :child_site_ids, type: [ Integer ]
      optional :default_policy, type: Boolean
      optional :policy_type, type: String
      optional :name, type: String
      optional :description, type: String
    end
    patch "/api/rest/v1/child_site_management_policies/:id" do
      status 200
      { "id" => 1, "policy_type" => "settings", "name" => "example", "description" => "example", "value" => "{ \"color2_left\": \"#000000\", \"folder_behaviors\": [{ \"behavior\": \"file_expiration\", \"value\": { \"days_to_retain\": 30 } }] }", "applied_child_site_ids" => [ 1, 2 ], "skip_child_site_ids" => [ 1, 2 ], "child_site_ids" => [ 1, 2 ], "default_policy" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
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
