module FilesMockServer
  class HistoryExportAPI < Grape::API
    format :json

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/history_exports/:id" do
      status 200
      { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "status" => "ready", "query_action" => "read", "query_interface" => "ftp", "query_user_id" => "1", "query_file_id" => "1", "query_parent_id" => "1", "query_path" => "MyFile.txt", "query_folder" => "Folder", "query_src" => "SrcFolder", "query_destination" => "DestFolder", "query_ip" => "127.0.0.1", "query_username" => "jerry", "query_failure_type" => "bad_password", "query_target_id" => "1", "query_target_name" => "full", "query_target_permission" => "full", "query_target_user_id" => "1", "query_target_username" => "jerry", "query_target_platform" => "windows", "query_target_permission_set" => "desktop_app", "results_url" => "https://files.com/history_results.csv" }
    end

    params do
      optional :user_id, type: Integer
      optional :start_at, type: String
      optional :end_at, type: String
      optional :query_action, type: String
      optional :query_interface, type: String
      optional :query_user_id, type: String
      optional :query_file_id, type: String
      optional :query_parent_id, type: String
      optional :query_path, type: String
      optional :query_folder, type: String
      optional :query_src, type: String
      optional :query_destination, type: String
      optional :query_ip, type: String
      optional :query_username, type: String
      optional :query_failure_type, type: String
      optional :query_target_id, type: String
      optional :query_target_name, type: String
      optional :query_target_permission, type: String
      optional :query_target_user_id, type: String
      optional :query_target_username, type: String
      optional :query_target_platform, type: String
      optional :query_target_permission_set, type: String
    end
    post "/api/rest/v1/history_exports" do
      status 201
      { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "status" => "ready", "query_action" => "read", "query_interface" => "ftp", "query_user_id" => "1", "query_file_id" => "1", "query_parent_id" => "1", "query_path" => "MyFile.txt", "query_folder" => "Folder", "query_src" => "SrcFolder", "query_destination" => "DestFolder", "query_ip" => "127.0.0.1", "query_username" => "jerry", "query_failure_type" => "bad_password", "query_target_id" => "1", "query_target_name" => "full", "query_target_permission" => "full", "query_target_user_id" => "1", "query_target_username" => "jerry", "query_target_platform" => "windows", "query_target_permission_set" => "desktop_app", "results_url" => "https://files.com/history_results.csv" }
    end
  end
end
