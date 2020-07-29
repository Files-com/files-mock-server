module FilesMockServer
  class SettingsChangeAPI < Grape::API
    format :json

    params do
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
    get "/api/rest/v1/settings_changes" do
      status 200
      [ { "change_details" => "{ domain: [\"olddomain.com', \"newdomain.com\"] }", "created_at" => "2000-01-01T01:00:00Z", "user_id" => 1 } ]
    end
  end
end
