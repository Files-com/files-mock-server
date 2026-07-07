module FilesMockServer
  class SsoEventAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/sso_events" do
      status 200
      [ { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "event_errors" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "user_id" => 1, "username" => "example", "idp_uid" => "example", "provider" => "example", "provider_label" => "example", "ip" => "example", "region" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sso_events/:id" do
      status 200
      { "id" => 1, "event_type" => "example", "status" => "example", "body" => "example", "event_errors" => [ "example" ], "created_at" => "2000-01-01T01:00:00Z", "body_url" => "example", "user_id" => 1, "username" => "example", "idp_uid" => "example", "provider" => "example", "provider_label" => "example", "ip" => "example", "region" => "example" }
    end
  end
end
