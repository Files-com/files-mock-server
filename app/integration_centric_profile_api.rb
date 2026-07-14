module FilesMockServer
  class IntegrationCentricProfileAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/integration_centric_profiles" do
      status 200
      [ { "id" => 1, "name" => "Business Systems Onboarding", "workspace_id" => 1, "use_for_all_users" => true, "expected_remote_servers" => [ "example" ] } ]
    end

    params do
      requires :name, type: String
      requires :expected_remote_servers, type: [ Hash ]
      optional :workspace_id, type: Integer
      optional :use_for_all_users, type: Boolean
    end
    post "/api/rest/v1/integration_centric_profiles" do
      status 201
      { "id" => 1, "name" => "Business Systems Onboarding", "workspace_id" => 1, "use_for_all_users" => true, "expected_remote_servers" => [ "example" ] }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/integration_centric_profiles/:id" do
      status 200
      { "id" => 1, "name" => "Business Systems Onboarding", "workspace_id" => 1, "use_for_all_users" => true, "expected_remote_servers" => [ "example" ] }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
      optional :expected_remote_servers, type: [ Hash ]
      optional :use_for_all_users, type: Boolean
    end
    patch "/api/rest/v1/integration_centric_profiles/:id" do
      status 200
      { "id" => 1, "name" => "Business Systems Onboarding", "workspace_id" => 1, "use_for_all_users" => true, "expected_remote_servers" => [ "example" ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/integration_centric_profiles/:id" do
      status 204
      body false
    end
  end
end
