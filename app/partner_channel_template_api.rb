module FilesMockServer
  class PartnerChannelTemplateAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/partner_channel_templates" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Claims Template", "path" => "claims/medical", "to_partner_folder_name" => "outgoing", "from_partner_folder_name" => "incoming", "from_partner_route_path_pattern" => "processing/{{partner_name}}/from-partner", "to_partner_route_path_pattern" => "delivery/{{partner_name}}/to-partner", "to_partner_managed_folder_paths" => [ "reports/monthly" ], "from_partner_managed_folder_paths" => [ "claims/received" ], "effective_to_partner_folder_name" => "outgoing", "effective_from_partner_folder_name" => "incoming" } ]
    end

    params do
      optional :from_partner_folder_name, type: String
      optional :from_partner_managed_folder_paths, type: [ String ]
      optional :from_partner_route_path_pattern, type: String
      optional :to_partner_folder_name, type: String
      optional :to_partner_managed_folder_paths, type: [ String ]
      optional :to_partner_route_path_pattern, type: String
      requires :name, type: String
      requires :path, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/partner_channel_templates" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Claims Template", "path" => "claims/medical", "to_partner_folder_name" => "outgoing", "from_partner_folder_name" => "incoming", "from_partner_route_path_pattern" => "processing/{{partner_name}}/from-partner", "to_partner_route_path_pattern" => "delivery/{{partner_name}}/to-partner", "to_partner_managed_folder_paths" => [ "reports/monthly" ], "from_partner_managed_folder_paths" => [ "claims/received" ], "effective_to_partner_folder_name" => "outgoing", "effective_from_partner_folder_name" => "incoming" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/partner_channel_templates/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Claims Template", "path" => "claims/medical", "to_partner_folder_name" => "outgoing", "from_partner_folder_name" => "incoming", "from_partner_route_path_pattern" => "processing/{{partner_name}}/from-partner", "to_partner_route_path_pattern" => "delivery/{{partner_name}}/to-partner", "to_partner_managed_folder_paths" => [ "reports/monthly" ], "from_partner_managed_folder_paths" => [ "claims/received" ], "effective_to_partner_folder_name" => "outgoing", "effective_from_partner_folder_name" => "incoming" }
    end

    params do
      requires :id, type: Integer
      optional :from_partner_folder_name, type: String
      optional :from_partner_managed_folder_paths, type: [ String ]
      optional :from_partner_route_path_pattern, type: String
      optional :to_partner_folder_name, type: String
      optional :to_partner_managed_folder_paths, type: [ String ]
      optional :to_partner_route_path_pattern, type: String
      optional :name, type: String
      optional :path, type: String
    end
    patch "/api/rest/v1/partner_channel_templates/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Claims Template", "path" => "claims/medical", "to_partner_folder_name" => "outgoing", "from_partner_folder_name" => "incoming", "from_partner_route_path_pattern" => "processing/{{partner_name}}/from-partner", "to_partner_route_path_pattern" => "delivery/{{partner_name}}/to-partner", "to_partner_managed_folder_paths" => [ "reports/monthly" ], "from_partner_managed_folder_paths" => [ "claims/received" ], "effective_to_partner_folder_name" => "outgoing", "effective_from_partner_folder_name" => "incoming" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/partner_channel_templates/:id" do
      status 204
      body false
    end
  end
end
