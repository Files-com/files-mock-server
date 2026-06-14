module FilesMockServer
  class PartnerSiteAPI < Grape::API
    format :json

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/partner_sites/:id" do
      status 204
      body false
    end
  end
end
