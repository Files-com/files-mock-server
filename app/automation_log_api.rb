module FilesMockServer
  class AutomationLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/automation_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "automation_id" => 1, "automation_run_id" => 1, "dest_path" => "example", "error_type" => "example", "message" => "example", "operation" => "copy", "path" => "example", "status" => "success", "created_at" => "2000-01-01T01:00:00Z", "log_type" => "example" } ]
    end

    params do
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    post "/api/rest/v1/automation_logs/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
