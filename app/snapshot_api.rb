module FilesMockServer
  class SnapshotAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/snapshots" do
      status 200
      [ { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "finalized_at" => "2000-01-01T01:00:00Z", "name" => "My Snapshot", "user_id" => 1, "bundle_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/snapshots/:id" do
      status 200
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "finalized_at" => "2000-01-01T01:00:00Z", "name" => "My Snapshot", "user_id" => 1, "bundle_id" => 1 }
    end

    params do
      optional :expires_at, type: String
      optional :name, type: String
      optional :paths, type: [ String ]
    end
    post "/api/rest/v1/snapshots" do
      status 201
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "finalized_at" => "2000-01-01T01:00:00Z", "name" => "My Snapshot", "user_id" => 1, "bundle_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :expires_at, type: String
      optional :name, type: String
      optional :paths, type: [ String ]
    end
    patch "/api/rest/v1/snapshots/:id" do
      status 200
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "finalized_at" => "2000-01-01T01:00:00Z", "name" => "My Snapshot", "user_id" => 1, "bundle_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/snapshots/:id" do
      status 204
      body false
    end
  end
end
