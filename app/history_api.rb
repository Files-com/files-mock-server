module FilesMockServer
  class HistoryAPI < Grape::API
    format :json

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      requires :path, type: String
    end
    get "/api/rest/v1/history/files/:path" do
      status 200
      [ { "id" => 1, "path" => "", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => nil, "user_id" => 1, "username" => "user", "user_is_from_parent_site" => true, "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      requires :path, type: String
    end
    get "/api/rest/v1/history/folders/:path" do
      status 200
      [ { "id" => 1, "path" => "", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => nil, "user_id" => 1, "username" => "user", "user_is_from_parent_site" => true, "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      requires :user_id, type: Integer
    end
    get "/api/rest/v1/history/users/:user_id" do
      status 200
      [ { "id" => 1, "path" => "", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => nil, "user_id" => 1, "username" => "user", "user_is_from_parent_site" => true, "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/history/login" do
      status 200
      [ { "id" => 1, "path" => "", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => nil, "user_id" => 1, "username" => "user", "user_is_from_parent_site" => true, "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/history" do
      status 200
      [ { "id" => 1, "path" => "", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => nil, "user_id" => 1, "username" => "user", "user_is_from_parent_site" => true, "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :sort_by, type: Hash
      requires :path, type: Integer
    end
    post "/api/rest/v1/history/files/:path/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :sort_by, type: Hash
      requires :path, type: Integer
    end
    post "/api/rest/v1/history/folders/:path/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :sort_by, type: Hash
      requires :user_id, type: Integer
    end
    post "/api/rest/v1/history/users/:user_id/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/history/login/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/history/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
