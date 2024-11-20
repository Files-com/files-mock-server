module FilesMockServer
  class BandwidthSnapshotAPI < Grape::API
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
    get "/api/rest/v1/bandwidth_snapshots" do
      status 200
      [ { "id" => 1, "bytes_received" => 1.0, "bytes_sent" => 1.0, "sync_bytes_received" => 1.0, "sync_bytes_sent" => 1.0, "requests_get" => 1.0, "requests_put" => 1.0, "requests_other" => 1.0, "logged_at" => "2000-01-01T01:00:00Z" } ]
    end

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
    post "/api/rest/v1/bandwidth_snapshots/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
