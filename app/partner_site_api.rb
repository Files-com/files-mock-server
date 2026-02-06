module FilesMockServer
  class PartnerSiteAPI < Grape::API
    format :json

    get "/api/rest/v1/partner_sites/linked_partner_sites" do
      status 200
      [ { "partner_id" => 1, "partner_name" => "Acme Corp", "linked_site_id" => 1, "linked_site_name" => "Acme's Partner Site", "main_site_id" => 2, "main_site_name" => "Acme Site" } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/partner_sites" do
      status 200
      [ { "partner_id" => 1, "partner_name" => "Acme Corp", "linked_site_id" => 1, "linked_site_name" => "Acme's Partner Site", "main_site_id" => 2, "main_site_name" => "Acme Site" } ]
    end
  end
end
