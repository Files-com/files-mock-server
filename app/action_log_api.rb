module FilesMockServer
  class ActionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/action_logs" do
      status 200
      [ { "action" => "example", "created_at" => "2000-01-01T01:00:00Z", "destination" => "example", "failure_type" => "example", "folder" => "example", "interface" => "example", "ip" => "example", "metadata_dm_id" => 1, "parent_metadata_dm_id" => 1, "path" => "example", "site_id" => 1, "src" => "example", "user_id" => 1, "username" => "example" } ]
    end
  end
end
