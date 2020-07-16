module FilesMockServer
  class AutomationAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :automation, type: String
    end
    get "/api/rest/v1/automations" do
      status 200
      [ { "id" => 1, "automation" => "create_folder", "source" => "", "destination" => "", "destination_replace_from" => "", "destination_replace_to" => "", "interval" => "week", "next_process_on" => "2020-01-01", "path" => "", "realtime" => true, "user_id" => 1, "user_ids" => [], "group_ids" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "automation" => "create_folder", "source" => "", "destination" => "", "destination_replace_from" => "", "destination_replace_to" => "", "interval" => "week", "next_process_on" => "2020-01-01", "path" => "", "realtime" => true, "user_id" => 1, "user_ids" => [], "group_ids" => [] }
    end

    params do
      requires :automation, type: String
      optional :source, type: String
      optional :destination, type: String
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
    end
    post "/api/rest/v1/automations" do
      status 201
      { "id" => 1, "automation" => "create_folder", "source" => "", "destination" => "", "destination_replace_from" => "", "destination_replace_to" => "", "interval" => "week", "next_process_on" => "2020-01-01", "path" => "", "realtime" => true, "user_id" => 1, "user_ids" => [], "group_ids" => [] }
    end

    params do
      requires :id, type: Integer
      requires :automation, type: String
      optional :source, type: String
      optional :destination, type: String
      optional :destination_replace_from, type: String
      optional :destination_replace_to, type: String
      optional :interval, type: String
      optional :path, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
    end
    patch "/api/rest/v1/automations/:id" do
      status 200
      { "id" => 1, "automation" => "create_folder", "source" => "", "destination" => "", "destination_replace_from" => "", "destination_replace_to" => "", "interval" => "week", "next_process_on" => "2020-01-01", "path" => "", "realtime" => true, "user_id" => 1, "user_ids" => [], "group_ids" => [] }
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
