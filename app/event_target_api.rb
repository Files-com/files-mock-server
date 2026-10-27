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
      [ { "id" => 1, "name" => "example", "target_type" => "webhook", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => { "url" => "https://example.com/files-events", "headers" => { "X-Example" => "value" }, "use_dedicated_ips" => false }, "delivery_policy" => { "max_attempts" => 3, "retry_delay_minutes" => [ 1, 10 ] }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :name, type: String
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :enabled, type: Boolean
      requires :config, type: Hash
      optional :delivery_policy, type: Hash
      requires :target_type, type: String
    end
    post "/api/rest/v1/event_targets" do
      status 201
      { "id" => 1, "name" => "example", "target_type" => "webhook", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => { "url" => "https://example.com/files-events", "headers" => { "X-Example" => "value" }, "use_dedicated_ips" => false }, "delivery_policy" => { "max_attempts" => 3, "retry_delay_minutes" => [ 1, 10 ] }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_targets/:id" do
      status 200
      { "id" => 1, "name" => "example", "target_type" => "webhook", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => { "url" => "https://example.com/files-events", "headers" => { "X-Example" => "value" }, "use_dedicated_ips" => false }, "delivery_policy" => { "max_attempts" => 3, "retry_delay_minutes" => [ 1, 10 ] }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :enabled, type: Boolean
      optional :config, type: Hash
      optional :delivery_policy, type: Hash
    end
    patch "/api/rest/v1/event_targets/:id" do
      status 200
      { "id" => 1, "name" => "example", "target_type" => "webhook", "workspace_id" => 1, "apply_to_all_workspaces" => true, "enabled" => true, "config" => { "url" => "https://example.com/files-events", "headers" => { "X-Example" => "value" }, "use_dedicated_ips" => false }, "delivery_policy" => { "max_attempts" => 3, "retry_delay_minutes" => [ 1, 10 ] }, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
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
