module FilesMockServer
  class PartnerSiteRequestAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/partner_site_requests" do
      status 200
      [ { "id" => 1, "partner_id" => 1, "linked_site_id" => 1, "status" => "pending", "pairing_key" => "abc123xyz", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :pairing_key, type: String
    end
    get "/api/rest/v1/partner_site_requests/find_by_pairing_key" do
      status 204
      body false
    end

    params do
      requires :partner_id, type: Integer
      requires :site_url, type: String
    end
    post "/api/rest/v1/partner_site_requests" do
      status 201
      { "id" => 1, "partner_id" => 1, "linked_site_id" => 1, "status" => "pending", "pairing_key" => "abc123xyz", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/partner_site_requests/:id/reject" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/partner_site_requests/:id/approve" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/partner_site_requests/:id" do
      status 204
      body false
    end
  end
end
