module FilesMockServer
  class SiemHttpDestinationEventAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/siem_http_destination_events" do
      status 200
      [ { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "event_errors" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "siem_http_destination_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/siem_http_destination_events/:id" do
      status 200
      { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "event_errors" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "siem_http_destination_id" => 1 }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    post "/api/rest/v1/siem_http_destination_events/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
