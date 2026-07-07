module FilesMockServer
  class FrontendMetricAPI < Grape::API
    format :json

    params do
      requires :metric_type, type: String
      requires :subkey, type: String
      optional :ms, type: Integer
    end
    post "/api/rest/v1/frontend_metrics" do
      status 201
      { "metric_type" => "increment", "subkey" => "abc123", "ms" => 100 }
    end
  end
end
