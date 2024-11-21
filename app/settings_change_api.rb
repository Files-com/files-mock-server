module FilesMockServer
  class SettingsChangeAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/settings_changes" do
      status 200
      [ { "changes" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "user_id" => 1, "api_key_id" => 1, "user_is_files_support" => true, "user_is_from_parent_site" => true, "username" => "some_user" } ]
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/settings_changes/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
