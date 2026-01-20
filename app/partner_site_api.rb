module FilesMockServer
  class PartnerSiteAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/partner_sites" do
      status 200
      [ { "partner_id" => 1, "partner_name" => "Acme Corp", "linked_site_id" => 1 } ]
    end
  end
end
