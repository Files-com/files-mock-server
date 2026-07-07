module FilesMockServer
  class ClickwrapAcceptanceAPI < Grape::API
    format :json

    params do
      requires :clickwrap_id, type: Integer
    end
    post "/api/rest/v1/clickwrap_acceptances" do
      status 201
      { "id" => 1, "clickwrap_id" => 1, "created_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
