module FilesMockServer
  class HistoryExportResultAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :history_export_id, type: Integer
    end
    get "/api/rest/v1/history_export_results" do
      status 200
      [ { "id" => 1, "created_at" => 1, "created_at_iso8601" => "example", "user_id" => 1, "file_id" => 1, "parent_id" => 1, "path" => "MyFile.txt", "folder" => "Folder", "src" => "SrcFolder", "destination" => "DestFolder", "ip" => "127.0.0.1", "username" => "jerry", "user_is_from_parent_site" => true, "action" => "read", "failure_type" => "bad_password", "interface" => "ftp", "target_id" => 1, "target_name" => "full", "target_permission" => "full", "target_recursive" => true, "target_expires_at" => 1, "target_expires_at_iso8601" => "example", "target_permission_set" => "desktop_app", "target_platform" => "windows", "target_username" => "jerry", "target_user_id" => 1 } ]
    end

    params do
      optional :user_id, type: Integer
      requires :history_export_id, type: Integer
    end
    post "/api/rest/v1/history_export_results/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
