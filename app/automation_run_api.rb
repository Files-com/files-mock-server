module FilesMockServer
  class AutomationRunAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      requires :automation_id, type: Integer
    end
    get "/api/rest/v1/automation_runs" do
      status 200
      [ { "id" => 1, "automation_id" => 1, "automation_version_id" => 1, "workspace_id" => 1, "cancel_requested_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "status" => "success", "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/automation_runs/:id" do
      status 200
      { "id" => 1, "automation_id" => 1, "automation_version_id" => 1, "workspace_id" => 1, "cancel_requested_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "status" => "success", "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" }
    end

    params do
      requires :id, type: Integer
      requires :node_id, type: String
    end
    get "/api/rest/v1/automation_runs/:id/node" do
      status 200
      { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/automation_runs/:id/cancel" do
      status 200
      { "id" => 1, "automation_id" => 1, "automation_version_id" => 1, "workspace_id" => 1, "cancel_requested_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "status" => "success", "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" }
    end

    params do
      requires :id, type: Integer
      requires :node_id, type: String
    end
    post "/api/rest/v1/automation_runs/:id/rerun" do
      status 201
      { "id" => 1, "automation_id" => 1, "automation_version_id" => 1, "workspace_id" => 1, "cancel_requested_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "status" => "success", "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" }
    end
  end
end
