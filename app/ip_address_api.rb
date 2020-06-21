module FilesMockServer
  class IpAddressAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/ip_addresses" do
      status 200
      [{"id"=>"Site", "associated_with"=>"Site", "group_id"=>1, "ip_addresses"=>[]}]
    end
  end
end
