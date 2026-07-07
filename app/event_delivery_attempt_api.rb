module FilesMockServer
  class EventDeliveryAttemptAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/event_delivery_attempts" do
      status 200
      [ { "id" => 1, "event_record_id" => 1, "event_subscription_id" => 1, "event_target_id" => 1, "workspace_id" => 1, "status" => "example", "attempt_number" => 1, "response_code" => 1, "error_message" => "example", "response_body" => "example", "latency_ms" => 1, "delivered_at" => "2000-01-01T01:00:00Z", "last_attempted_at" => "2000-01-01T01:00:00Z", "next_attempt_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_delivery_attempts/:id" do
      status 200
      { "id" => 1, "event_record_id" => 1, "event_subscription_id" => 1, "event_target_id" => 1, "workspace_id" => 1, "status" => "example", "attempt_number" => 1, "response_code" => 1, "error_message" => "example", "response_body" => "example", "latency_ms" => 1, "delivered_at" => "2000-01-01T01:00:00Z", "last_attempted_at" => "2000-01-01T01:00:00Z", "next_attempt_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/event_delivery_attempts/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
