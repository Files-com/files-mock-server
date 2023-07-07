module FilesMockServer
  class AutomationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :with_deleted, type: Boolean
    end
    get "/api/rest/v1/automations" do
      status 200
      [ { "id" => 1, "automation" => "create_folder", "deleted" => true, "disabled" => true, "trigger" => "daily", "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "name" => "example", "schedule" => "example", "source" => "example", "destinations" => [ "destination" ], "destination_replace_from" => "example", "destination_replace_to" => "example", "description" => "example", "recurring_day" => 25, "path" => "example", "user_id" => 1, "sync_ids" => [ 1, 2 ], "user_ids" => [ 1, 2 ], "group_ids" => [ 1, 2 ], "webhook_url" => "https://app.files.com/api/webhooks/abc123", "trigger_actions" => [ "create" ], "value" => { "limit" => "1" } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "automation" => "create_folder", "deleted" => true, "disabled" => true, "trigger" => "daily", "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "name" => "example", "schedule" => "example", "source" => "example", "destinations" => [ "destination" ], "destination_replace_from" => "example", "destination_replace_to" => "example", "description" => "example", "recurring_day" => 25, "path" => "example", "user_id" => 1, "sync_ids" => [ 1, 2 ], "user_ids" => [ 1, 2 ], "group_ids" => [ 1, 2 ], "webhook_url" => "https://app.files.com/api/webhooks/abc123", "trigger_actions" => [ "create" ], "value" => { "limit" => "1" } }
    end

    params do
      optional :source, type: String
      optional :destination, type: String
      optional :destinations, type: Array[String]
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :sync_ids, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
      optional :schedule, type: Hash
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :name, type: String
      optional :trigger, type: String
      optional :trigger_actions, type: Array[String]
      optional :value, type: Hash
      optional :recurring_day, type: Integer
      requires :automation, type: String
    end
    post "/api/rest/v1/automations" do
      status 201
      { "id" => 1, "automation" => "create_folder", "deleted" => true, "disabled" => true, "trigger" => "daily", "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "name" => "example", "schedule" => "example", "source" => "example", "destinations" => [ "destination" ], "destination_replace_from" => "example", "destination_replace_to" => "example", "description" => "example", "recurring_day" => 25, "path" => "example", "user_id" => 1, "sync_ids" => [ 1, 2 ], "user_ids" => [ 1, 2 ], "group_ids" => [ 1, 2 ], "webhook_url" => "https://app.files.com/api/webhooks/abc123", "trigger_actions" => [ "create" ], "value" => { "limit" => "1" } }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/automations/:id/manual_run" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :source, type: String
      optional :destination, type: String
      optional :destinations, type: Array[String]
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :sync_ids, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
      optional :schedule, type: Hash
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :name, type: String
      optional :trigger, type: String
      optional :trigger_actions, type: Array[String]
      optional :value, type: Hash
      optional :recurring_day, type: Integer
      optional :automation, type: String
    end
    patch "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "automation" => "create_folder", "deleted" => true, "disabled" => true, "trigger" => "daily", "interval" => "week", "last_modified_at" => "2000-01-01T01:00:00Z", "name" => "example", "schedule" => "example", "source" => "example", "destinations" => [ "destination" ], "destination_replace_from" => "example", "destination_replace_to" => "example", "description" => "example", "recurring_day" => 25, "path" => "example", "user_id" => 1, "sync_ids" => [ 1, 2 ], "user_ids" => [ 1, 2 ], "group_ids" => [ 1, 2 ], "webhook_url" => "https://app.files.com/api/webhooks/abc123", "trigger_actions" => [ "create" ], "value" => { "limit" => "1" } }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/automations/:id" do
      status 204
      body false
    end
  end
end
