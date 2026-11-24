module FilesMockServer
  class SharedWorkflowAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/shared_workflows" do
      status 200
      [ { "id" => 1, "name" => "example", "description" => "example", "submission_revision" => "example", "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/shared_workflows/:id" do
      status 200
      { "id" => 1, "name" => "example", "description" => "example", "submission_revision" => "example", "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] }
    end

    params do
      requires :id, type: Integer
      requires :submission_revision, type: String
      requires :submission_id, type: String
      requires :file_path, type: String
    end
    post "/api/rest/v1/shared_workflows/:id/run_workflow" do
      status 201
      { "id" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "status" => "success", "automation_id" => 1, "automation_version_id" => 1, "version" => 1, "workspace_id" => 1, "initiating_user_id" => 1, "initiating_interface" => "example", "cancel_requested_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" }
    end

    params do
      requires :id, type: Integer
      requires :run_id, type: Integer
    end
    get "/api/rest/v1/shared_workflows/:id/runs/:run_id" do
      status 200
      { "id" => 1, "completed_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "status" => "success", "automation_id" => 1, "automation_version_id" => 1, "version" => 1, "workspace_id" => 1, "initiating_user_id" => 1, "initiating_interface" => "example", "cancel_requested_at" => "2000-01-01T01:00:00Z", "retry_at" => "2000-01-01T01:00:00Z", "retried_at" => "2000-01-01T01:00:00Z", "retried_in_run_id" => 1, "retry_of_run_id" => 1, "rerun_of_run_id" => 1, "rerun_from_node_id" => "example", "runtime" => 1.0, "successful_operations" => 1, "failed_operations" => 1, "definition" => "example", "node_states" => "example", "execution_nodes" => [ { "node_id" => "example", "node_type" => "example", "status" => "example", "run_stage" => "example", "reused" => true, "successful_operations" => 1, "failed_operations" => 1, "started_at" => "2000-01-01T01:00:00Z", "completed_at" => "2000-01-01T01:00:00Z", "duration_ms" => 1, "inputs" => [ "example" ], "outputs" => "example", "input_items" => "example", "output_items" => "example" } ], "journal_url" => "example", "status_messages_url" => "https://www.example.com/log_file.txt" }
    end
  end
end
