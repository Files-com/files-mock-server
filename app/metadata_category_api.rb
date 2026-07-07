module FilesMockServer
  class MetadataCategoryAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/metadata_categories" do
      status 200
      [ { "id" => 1, "name" => "Approval Workflow", "definitions" => { "Approval Status" => [ "Under Review", "Approved", "Rejected" ], "Reviewer" => [] }, "default_columns" => [ "Approval Status" ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/metadata_categories/:id" do
      status 200
      { "id" => 1, "name" => "Approval Workflow", "definitions" => { "Approval Status" => [ "Under Review", "Approved", "Rejected" ], "Reviewer" => [] }, "default_columns" => [ "Approval Status" ] }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :path, type: String
    end
    get "/api/rest/v1/metadata_categories/list_by_path/:path" do
      status 200
      [ { "id" => 1, "name" => "Approval Workflow", "definitions" => { "Approval Status" => [ "Under Review", "Approved", "Rejected" ], "Reviewer" => [] }, "default_columns" => [ "Approval Status" ] } ]
    end

    params do
      requires :name, type: String
      optional :default_columns, type: [ String ]
    end
    post "/api/rest/v1/metadata_categories" do
      status 201
      { "id" => 1, "name" => "Approval Workflow", "definitions" => { "Approval Status" => [ "Under Review", "Approved", "Rejected" ], "Reviewer" => [] }, "default_columns" => [ "Approval Status" ] }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :default_columns, type: [ String ]
    end
    patch "/api/rest/v1/metadata_categories/:id" do
      status 200
      { "id" => 1, "name" => "Approval Workflow", "definitions" => { "Approval Status" => [ "Under Review", "Approved", "Rejected" ], "Reviewer" => [] }, "default_columns" => [ "Approval Status" ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/metadata_categories/:id" do
      status 204
      body false
    end
  end
end
