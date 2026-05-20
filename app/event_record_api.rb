module FilesMockServer
  class EventRecordAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/event_records" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "event_uuid" => "example", "event_type" => "example", "severity" => "example", "source_type" => "example", "source_id" => 1, "occurred_at" => "2000-01-01T01:00:00Z", "human_title" => "example", "human_summary" => "example", "human_fields" => [ "example" ], "actor" => "example", "resources" => [ "example" ], "payload" => "example", "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_records/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "event_uuid" => "example", "event_type" => "example", "severity" => "example", "source_type" => "example", "source_id" => 1, "occurred_at" => "2000-01-01T01:00:00Z", "human_title" => "example", "human_summary" => "example", "human_fields" => [ "example" ], "actor" => "example", "resources" => [ "example" ], "payload" => "example", "created_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
