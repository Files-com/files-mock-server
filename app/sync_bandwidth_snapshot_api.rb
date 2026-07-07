module FilesMockServer
  class SyncBandwidthSnapshotAPI < Grape::API
    format :json

    params do
      requires :remote_server_id, type: Integer
      requires :sync_bytes_sent, type: Integer
      requires :sync_bytes_received, type: Integer
    end
    post "/api/rest/v1/sync_bandwidth_snapshots" do
      status 201
      { "id" => 1, "site_id" => 123, "sync_bytes_received" => "1.0", "sync_bytes_sent" => "1.0", "created_at" => "2000-01-01T01:00:00Z" }
    end

    post "/api/rest/v1/sync_bandwidth_snapshots/create_batch" do
      status 201
      [ { "id" => 1, "site_id" => 123, "sync_bytes_received" => "1.0", "sync_bytes_sent" => "1.0", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
