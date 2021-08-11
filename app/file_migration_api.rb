module FilesMockServer
  class FileMigrationAPI < Grape::API
    format :json

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/file_migrations/:id" do
      status 200
      { "id" => 1, "path" => "MyFolder", "dest_path" => "MyFolder", "files_moved" => 1, "files_total" => 1, "operation" => "move", "region" => "USA", "status" => "complete", "log_url" => "https://www.example.com/log_file" }
    end
  end
end
