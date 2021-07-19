module FilesMockServer
  class ActionWebhookFailureAPI < Grape::API
    format :json

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/action_webhook_failures/:id/retry" do
      status 201
      body false
    end
  end
end
