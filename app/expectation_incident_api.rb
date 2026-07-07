module FilesMockServer
  class ExpectationIncidentAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/expectation_incidents" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_at" => "2000-01-01T01:00:00Z", "last_failed_at" => "2000-01-01T01:00:00Z", "acknowledged_at" => "2000-01-01T01:00:00Z", "snoozed_until" => "2000-01-01T01:00:00Z", "resolved_at" => "2000-01-01T01:00:00Z", "opened_by_evaluation_id" => 1, "last_evaluation_id" => 2, "resolved_by_evaluation_id" => 3, "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/expectation_incidents/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_at" => "2000-01-01T01:00:00Z", "last_failed_at" => "2000-01-01T01:00:00Z", "acknowledged_at" => "2000-01-01T01:00:00Z", "snoozed_until" => "2000-01-01T01:00:00Z", "resolved_at" => "2000-01-01T01:00:00Z", "opened_by_evaluation_id" => 1, "last_evaluation_id" => 2, "resolved_by_evaluation_id" => 3, "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/expectation_incidents/:id/resolve" do
      status 200
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_at" => "2000-01-01T01:00:00Z", "last_failed_at" => "2000-01-01T01:00:00Z", "acknowledged_at" => "2000-01-01T01:00:00Z", "snoozed_until" => "2000-01-01T01:00:00Z", "resolved_at" => "2000-01-01T01:00:00Z", "opened_by_evaluation_id" => 1, "last_evaluation_id" => 2, "resolved_by_evaluation_id" => 3, "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      requires :snoozed_until, type: String
    end
    post "/api/rest/v1/expectation_incidents/:id/snooze" do
      status 200
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_at" => "2000-01-01T01:00:00Z", "last_failed_at" => "2000-01-01T01:00:00Z", "acknowledged_at" => "2000-01-01T01:00:00Z", "snoozed_until" => "2000-01-01T01:00:00Z", "resolved_at" => "2000-01-01T01:00:00Z", "opened_by_evaluation_id" => 1, "last_evaluation_id" => 2, "resolved_by_evaluation_id" => 3, "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/expectation_incidents/:id/acknowledge" do
      status 200
      { "id" => 1, "workspace_id" => 1, "expectation_id" => 1, "status" => "open", "opened_at" => "2000-01-01T01:00:00Z", "last_failed_at" => "2000-01-01T01:00:00Z", "acknowledged_at" => "2000-01-01T01:00:00Z", "snoozed_until" => "2000-01-01T01:00:00Z", "resolved_at" => "2000-01-01T01:00:00Z", "opened_by_evaluation_id" => 1, "last_evaluation_id" => 2, "resolved_by_evaluation_id" => 3, "summary" => nil, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
