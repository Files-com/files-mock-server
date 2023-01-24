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
      [ { "id" => 1, "created_at" => 1, "created_at_iso8601" => 1, "user_id" => 1, "file_id" => 1, "parent_id" => 1, "path" => "MyFile.txt", "folder" => "Folder", "src" => "SrcFolder", "destination" => "DestFolder", "ip" => "127.0.0.1", "username" => "jerry", "action" => "read", "failure_type" => "bad_password", "interface" => "ftp", "target_id" => 1, "target_name" => "full", "target_permission" => "full", "target_recursive" => true, "target_expires_at" => 1, "target_permission_set" => "desktop_app", "target_platform" => "windows", "target_username" => "jerry", "target_user_id" => 1 } ]
    end
  end
end
