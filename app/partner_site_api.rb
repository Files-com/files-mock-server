module FilesMockServer
  class PartnerSiteAPI < Grape::API
    format :json

    get "/api/rest/v1/partner_sites/linked_partner_sites" do
      status 200
      [ { "host_partner_id" => 1, "host_partner_name" => "Acme Corp", "guest_partner_id" => 2, "guest_partner_name" => "Example Corp", "host_site_id" => 1, "host_site_name" => "Acme Site", "guest_site_id" => 2, "guest_site_name" => "Example Site", "workspace_id" => 1 } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/partner_sites" do
      status 200
      [ { "host_partner_id" => 1, "host_partner_name" => "Acme Corp", "guest_partner_id" => 2, "guest_partner_name" => "Example Corp", "host_site_id" => 1, "host_site_name" => "Acme Site", "guest_site_id" => 2, "guest_site_name" => "Example Site", "workspace_id" => 1 } ]
    end
  end
end
