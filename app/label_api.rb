module FilesMockServer
  class LabelAPI < Grape::API
    format :json

    get "/api/rest/v1/labels" do
      status 204
      body false
    end
  end
end
