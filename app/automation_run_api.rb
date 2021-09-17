module FilesMockServer
  class AutomationRunAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :automation_id, type: Integer
    end
    get "/api/rest/v1/automation_runs" do
      status 200
      [ { "automation_id" => 1, "status" => "success", "status_messages_url" => "https://www.example.com/log_file.txt" } ]
    end
  end
end
