module FilesMockServer
  class AutomationLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/automation_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "automation_id" => 1, "automation_run_id" => 1, "dest_path" => "example", "error_type" => "example", "message" => "example", "operation" => "example", "path" => "example", "status" => "example" } ]
    end
  end
end
