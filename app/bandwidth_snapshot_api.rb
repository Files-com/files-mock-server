module FilesMockServer
  class BandwidthSnapshotAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api/rest/v1/bandwidth_snapshots" do
      status 200
      [ { "id" => 1, "bytes_received" => 1.0, "bytes_sent" => 1.0, "requests_get" => 1.0, "requests_put" => 1.0, "requests_other" => 1.0, "logged_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end