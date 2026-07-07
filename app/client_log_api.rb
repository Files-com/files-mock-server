module FilesMockServer
  class ClientLogAPI < Grape::API
    format :json

    params do
      requires :identifier, type: String
      requires :body, type: String
    end
    post "/api/rest/v1/client_logs/log" do
      status 204
      body false
    end
  end
end
