module FilesMockServer
  class SiteSubdomainRedirectAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/site_subdomain_redirects" do
      status 200
      [ { "id" => 1, "subdomain" => "old-company", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/site_subdomain_redirects/:id" do
      status 200
      { "id" => 1, "subdomain" => "old-company", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/site_subdomain_redirects/:id" do
      status 204
      body false
    end
  end
end
