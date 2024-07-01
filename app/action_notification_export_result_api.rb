module FilesMockServer
  class ActionNotificationExportResultAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      requires :action_notification_export_id, type: Integer
    end
    get "/api/rest/v1/action_notification_export_results" do
      status 200
      [ { "id" => 1, "created_at" => 1, "status" => 200, "message" => "Success", "success" => true, "request_headers" => "{\"User-Agent\":\"Files.com Webhook\"}", "request_method" => "GET", "request_url" => "www.example.com/webhook_receiver", "path" => "MyFolder/MyFile.txt", "folder" => "MyFolder" } ]
    end
  end
end
