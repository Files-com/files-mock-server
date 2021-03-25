module FilesMockServer
  class WebhookTestAPI < Grape::API
    format :json

    params do
      requires :url, type: String
      optional :method, type: String
      optional :encoding, type: String
      optional :headers, type: Hash
      optional :body, type: Hash
      optional :action, type: String
    end
    post "/api/rest/v1/webhook_tests" do
      status 201
      { "code" => 200, "message" => "", "status" => "", "data" => "", "success" => true }
    end
  end
end
