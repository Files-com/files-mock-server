module FilesMockServer
  class ExternalEventAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/external_events" do
      status 200
      [ { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "folder_behavior_id" => 1, "successful_files" => 1, "errored_files" => 1, "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "remote_server_type" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/external_events/:id" do
      status 200
      { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "folder_behavior_id" => 1, "successful_files" => 1, "errored_files" => 1, "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "remote_server_type" => "example" }
    end

    params do
      requires :status, type: String
      requires :body, type: String
    end
    post "/api/rest/v1/external_events" do
      status 201
      { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "folder_behavior_id" => 1, "successful_files" => 1, "errored_files" => 1, "bytes_synced" => 1, "compared_files" => 1, "compared_folders" => 1, "remote_server_type" => "example" }
    end
  end
end
