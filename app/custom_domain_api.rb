module FilesMockServer
  class CustomDomainAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/custom_domains" do
      status 200
      [ { "id" => 1, "domain" => "files.example.com", "destination" => "site_alias", "dns_status" => "correct", "ssl_certificate_id" => 1, "brick_managed" => true, "folder_behavior_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/custom_domains/:id" do
      status 200
      { "id" => 1, "domain" => "files.example.com", "destination" => "site_alias", "dns_status" => "correct", "ssl_certificate_id" => 1, "brick_managed" => true, "folder_behavior_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :destination, type: String
      optional :folder_behavior_id, type: Integer
      optional :ssl_certificate_id, type: Integer
      requires :domain, type: String
    end
    post "/api/rest/v1/custom_domains" do
      status 201
      { "id" => 1, "domain" => "files.example.com", "destination" => "site_alias", "dns_status" => "correct", "ssl_certificate_id" => 1, "brick_managed" => true, "folder_behavior_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/custom_domains/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :destination, type: String
      optional :folder_behavior_id, type: Integer
      optional :ssl_certificate_id, type: Integer
      optional :domain, type: String
    end
    patch "/api/rest/v1/custom_domains/:id" do
      status 200
      { "id" => 1, "domain" => "files.example.com", "destination" => "site_alias", "dns_status" => "correct", "ssl_certificate_id" => 1, "brick_managed" => true, "folder_behavior_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/custom_domains/:id" do
      status 204
      body false
    end
  end
end
