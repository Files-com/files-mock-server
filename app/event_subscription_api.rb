module FilesMockServer
  class EventSubscriptionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/event_subscriptions" do
      status 200
      [ { "id" => 1, "event_channel_id" => 1, "workspace_id" => 1, "apply_to_all_workspaces" => true, "name" => "example", "enabled" => true, "event_types" => [ "example" ], "filter" => "example", "delivery_policy" => "example", "event_target_ids" => [ 1 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_subscriptions/:id" do
      status 200
      { "id" => 1, "event_channel_id" => 1, "workspace_id" => 1, "apply_to_all_workspaces" => true, "name" => "example", "enabled" => true, "event_types" => [ "example" ], "filter" => "example", "delivery_policy" => "example", "event_target_ids" => [ 1 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :event_channel_id, type: Integer
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      requires :name, type: String
      optional :enabled, type: Boolean
      optional :event_types, type: [ String ]
      optional :filter, type: Hash
      optional :delivery_policy, type: Hash
      optional :event_target_ids, type: [ Integer ]
    end
    post "/api/rest/v1/event_subscriptions" do
      status 201
      { "id" => 1, "event_channel_id" => 1, "workspace_id" => 1, "apply_to_all_workspaces" => true, "name" => "example", "enabled" => true, "event_types" => [ "example" ], "filter" => "example", "delivery_policy" => "example", "event_target_ids" => [ 1 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :event_channel_id, type: Integer
      optional :workspace_id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :name, type: String
      optional :enabled, type: Boolean
      optional :event_types, type: [ String ]
      optional :filter, type: Hash
      optional :delivery_policy, type: Hash
      optional :event_target_ids, type: [ Integer ]
    end
    patch "/api/rest/v1/event_subscriptions/:id" do
      status 200
      { "id" => 1, "event_channel_id" => 1, "workspace_id" => 1, "apply_to_all_workspaces" => true, "name" => "example", "enabled" => true, "event_types" => [ "example" ], "filter" => "example", "delivery_policy" => "example", "event_target_ids" => [ 1 ], "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/event_subscriptions/:id" do
      status 204
      body false
    end
  end
end
