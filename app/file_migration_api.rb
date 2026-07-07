module FilesMockServer
  class FileMigrationAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/file_migrations" do
      status 200
      [ { "id" => 1, "path" => "MyFolder", "dest_path" => "MyFolder", "failure_message" => "example", "files_moved" => 1, "files_total" => 1, "operation" => "move", "region" => "USA", "status" => "complete", "log_url" => "https://www.example.com/log_file" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/file_migrations/:id" do
      status 200
      { "id" => 1, "path" => "MyFolder", "dest_path" => "MyFolder", "failure_message" => "example", "files_moved" => 1, "files_total" => 1, "operation" => "move", "region" => "USA", "status" => "complete", "log_url" => "https://www.example.com/log_file" }
    end

    params do
      optional :user_id, type: Integer
    end
    post "/api/rest/v1/file_migrations/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
