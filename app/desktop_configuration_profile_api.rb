module FilesMockServer
  class DesktopConfigurationProfileAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/desktop_configuration_profiles" do
      status 200
      [ { "id" => 1, "name" => "North America Desktop Profile", "workspace_id" => 1, "use_for_all_users" => true, "disable_drive_mounting" => true, "mount_mappings" => { "key" => "example value" } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/desktop_configuration_profiles/:id" do
      status 200
      { "id" => 1, "name" => "North America Desktop Profile", "workspace_id" => 1, "use_for_all_users" => true, "disable_drive_mounting" => true, "mount_mappings" => { "key" => "example value" } }
    end

    params do
      requires :name, type: String
      requires :mount_mappings, type: Hash
      optional :workspace_id, type: Integer
      optional :use_for_all_users, type: Boolean
      optional :disable_drive_mounting, type: Boolean
    end
    post "/api/rest/v1/desktop_configuration_profiles" do
      status 201
      { "id" => 1, "name" => "North America Desktop Profile", "workspace_id" => 1, "use_for_all_users" => true, "disable_drive_mounting" => true, "mount_mappings" => { "key" => "example value" } }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :workspace_id, type: Integer
      optional :mount_mappings, type: Hash
      optional :use_for_all_users, type: Boolean
      optional :disable_drive_mounting, type: Boolean
    end
    patch "/api/rest/v1/desktop_configuration_profiles/:id" do
      status 200
      { "id" => 1, "name" => "North America Desktop Profile", "workspace_id" => 1, "use_for_all_users" => true, "disable_drive_mounting" => true, "mount_mappings" => { "key" => "example value" } }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/desktop_configuration_profiles/:id" do
      status 204
      body false
    end
  end
end
