module FilesMockServer
  class ExpectationEvaluationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/expectation_evaluations" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_via" => "manual", "opened_at" => "2000-01-01T01:00:00Z", "window_start_at" => "2000-01-01T01:00:00Z", "window_end_at" => "2000-01-01T01:00:00Z", "deadline_at" => "2000-01-01T01:00:00Z", "late_acceptance_cutoff_at" => "2000-01-01T01:00:00Z", "hard_close_at" => "2000-01-01T01:00:00Z", "closed_at" => "2000-01-01T01:00:00Z", "matched_files" => [], "missing_files" => [], "criteria_errors" => [], "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/expectation_evaluations/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_via" => "manual", "opened_at" => "2000-01-01T01:00:00Z", "window_start_at" => "2000-01-01T01:00:00Z", "window_end_at" => "2000-01-01T01:00:00Z", "deadline_at" => "2000-01-01T01:00:00Z", "late_acceptance_cutoff_at" => "2000-01-01T01:00:00Z", "hard_close_at" => "2000-01-01T01:00:00Z", "closed_at" => "2000-01-01T01:00:00Z", "matched_files" => [], "missing_files" => [], "criteria_errors" => [], "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
