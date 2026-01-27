module FilesMockServer
  class RemoteBandwidthSnapshotAPI < Grape::API
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
    get "/api/rest/v1/remote_bandwidth_snapshots" do
      status 200
      [ { "id" => 1, "sync_bytes_received" => "1.0", "sync_bytes_sent" => "1.0", "logged_at" => "2000-01-01T01:00:00Z", "remote_server_id" => 1 } ]
    end
  end
end
