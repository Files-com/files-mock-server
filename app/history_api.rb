module FilesMockServer
  class HistoryAPI < Grape::API
    format :json

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      requires :path, type: String
    end
    get "/api/rest/v1/history/files/:path" do
      status 200
      [ { "id" => 1, "path" => "path", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => [], "user_id" => 1, "username" => "user", "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      requires :path, type: String
    end
    get "/api/rest/v1/history/folders/:path" do
      status 200
      [ { "id" => 1, "path" => "path", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => [], "user_id" => 1, "username" => "user", "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      requires :user_id, type: Integer
    end
    get "/api/rest/v1/history/users/:user_id" do
      status 200
      [ { "id" => 1, "path" => "path", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => [], "user_id" => 1, "username" => "user", "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/history/login" do
      status 200
      [ { "id" => 1, "path" => "path", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => [], "user_id" => 1, "username" => "user", "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end

    params do
      optional :start_at, type: String
      optional :end_at, type: String
      optional :display, type: String
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/history" do
      status 200
      [ { "id" => 1, "path" => "path", "when" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "display" => "Actual text of the action here.", "ip" => "192.283.128.182", "source" => "/from_path", "targets" => [], "user_id" => 1, "username" => "user", "action" => "create", "failure_type" => "none", "interface" => "web" } ]
    end
  end
end
