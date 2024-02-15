module FilesMockServer
  class AutomationRunAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      requires :automation_id, type: Integer
    end
    get "/api/rest/v1/automation_runs" do
      status 200
      [ { "id" => 1, "automation_id" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "runtime" => "2000-01-01T01:00:00Z", "status" => "success", "run_stage" => "planning", "successful_operations" => 1, "failed_operations" => 1, "status_messages_url" => "https://www.example.com/log_file.txt" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automation_runs/:id" do
      status 200
      { "id" => 1, "automation_id" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "runtime" => "2000-01-01T01:00:00Z", "status" => "success", "run_stage" => "planning", "successful_operations" => 1, "failed_operations" => 1, "status_messages_url" => "https://www.example.com/log_file.txt" }
    end
  end
end
