module FilesMockServer
  class IpAddressAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses" do
      status 200
      [ { "id" => "Site", "associated_with" => "Site", "group_id" => 1, "ip_addresses" => [] } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses/reserved" do
      status 200
      [ { "ip_address" => "1.1.1.1", "server_name" => "server-1" } ]
    end
  end
end
