module FilesMockServer
  class ScimLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/scim_logs" do
      status 200
      [ { "id" => 1, "created_at" => "2023-01-01T12:00:00Z", "request_path" => "/api/scim/Users", "request_method" => "POST", "http_response_code" => "200", "user_agent" => "Okta", "request_json" => "example", "response_json" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/scim_logs/:id" do
      status 200
      { "id" => 1, "created_at" => "2023-01-01T12:00:00Z", "request_path" => "/api/scim/Users", "request_method" => "POST", "http_response_code" => "200", "user_agent" => "Okta", "request_json" => "example", "response_json" => "example" }
    end

    params do
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/scim_logs/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
