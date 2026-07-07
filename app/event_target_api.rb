module FilesMockServer
  class EventTargetAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/event_targets" do
      status 200
      [ { "id" => 1, "name" => "example", "target_type" => "example", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => "example", "delivery_policy" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_targets/:id" do
      status 200
      { "id" => 1, "name" => "example", "target_type" => "example", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => "example", "delivery_policy" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :name, type: String
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      requires :target_type, type: String
      optional :enabled, type: Boolean
      requires :config, type: Hash
      optional :delivery_policy, type: Hash
    end
    post "/api/rest/v1/event_targets" do
      status 201
      { "id" => 1, "name" => "example", "target_type" => "example", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => "example", "delivery_policy" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/event_targets/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :target_type, type: String
      optional :enabled, type: Boolean
      optional :config, type: Hash
      optional :delivery_policy, type: Hash
    end
    patch "/api/rest/v1/event_targets/:id" do
      status 200
      { "id" => 1, "name" => "example", "target_type" => "example", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => "example", "delivery_policy" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/event_targets/:id" do
      status 204
      body false
    end
  end
end
