module FilesMockServer
  class ActionNotificationExportAPI < Grape::API
    format :json

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/action_notification_exports/:id" do
      status 200
      { "id" => 1, "export_version" => "20201213.2", "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "status" => "ready", "query_path" => "MyFile.txt", "query_folder" => "MyFolder", "query_message" => "Connection Refused", "query_request_method" => "GET", "query_request_url" => "http://example.com/webhook", "query_status" => "200", "query_success" => true, "results_url" => "https://files.com/action_notification_results.csv" }
    end

    params do
      optional :user_id, type: Integer
      optional :start_at, type: String
      optional :end_at, type: String
      optional :query_message, type: String
      optional :query_request_method, type: String
      optional :query_request_url, type: String
      optional :query_status, type: String
      optional :query_success, type: Boolean
      optional :query_path, type: String
      optional :query_folder, type: String
    end
    post "/api/rest/v1/action_notification_exports" do
      status 201
      { "id" => 1, "export_version" => "20201213.2", "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "status" => "ready", "query_path" => "MyFile.txt", "query_folder" => "MyFolder", "query_message" => "Connection Refused", "query_request_method" => "GET", "query_request_url" => "http://example.com/webhook", "query_status" => "200", "query_success" => true, "results_url" => "https://files.com/action_notification_results.csv" }
    end
  end
end
