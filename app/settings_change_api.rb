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
      [ { "api_key_id" => 1, "changes" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "user_id" => 1, "user_is_files_support" => true, "user_is_from_parent_site" => true, "username" => "some_user" } ]
    end
  end
end
