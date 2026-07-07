module FilesMockServer
  class AgentProxyIdentityAPI < Grape::API
    format :json

    params do
      requires :ips, type: [ String ]
    end
    post "/api/rest/v1/agent_proxy_identities/lookup" do
      status 200
      [ { "ip" => "example", "status" => "example", "identities" => [ { "peer_id" => "example", "endpoints" => [ { "multiaddr" => "example" } ] } ] } ]
    end

    params do
      requires :private_ip, type: String
      requires :peer_id, type: String
    end
    post "/api/rest/v1/agent_proxy_identities/report" do
      status 204
      body false
    end
  end
end
