module FilesMockServer
  class KeyLifecycleRuleAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/key_lifecycle_rules" do
      status 200
      [ { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "apply_to_all_workspaces" => true, "name" => "inactive gpg keys", "workspace_id" => 12 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/key_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "apply_to_all_workspaces" => true, "name" => "inactive gpg keys", "workspace_id" => 12 }
    end

    params do
      optional :apply_to_all_workspaces, type: Boolean
      optional :key_type, type: String
      optional :inactivity_days, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/key_lifecycle_rules" do
      status 201
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "apply_to_all_workspaces" => true, "name" => "inactive gpg keys", "workspace_id" => 12 }
    end

    params do
      requires :id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :key_type, type: String
      optional :inactivity_days, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
    end
    patch "/api/rest/v1/key_lifecycle_rules/:id" do
      status 200
      { "id" => 1, "key_type" => "gpg", "inactivity_days" => 12, "apply_to_all_workspaces" => true, "name" => "inactive gpg keys", "workspace_id" => 12 }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/key_lifecycle_rules/:id" do
      status 204
      body false
    end
  end
end
