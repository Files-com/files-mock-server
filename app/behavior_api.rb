module FilesMockServer
  class BehaviorAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/behaviors" do
      status 200
      [ { "id" => 1, "path" => "example", "attachment_url" => "example", "behavior" => "webhook", "name" => "example", "description" => "example", "value" => { "key" => "example value" } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/behaviors/:id" do
      status 200
      { "id" => 1, "path" => "example", "attachment_url" => "example", "behavior" => "webhook", "name" => "example", "description" => "example", "value" => { "key" => "example value" } }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
      requires :path, type: String
      optional :recursive, type: String
      optional :behavior, type: String
    end
    get "/api/rest/v1/behaviors/folders/:path" do
      status 200
      [ { "id" => 1, "path" => "example", "attachment_url" => "example", "behavior" => "webhook", "name" => "example", "description" => "example", "value" => { "key" => "example value" } } ]
    end

    params do
      optional :value, type: String
      optional :attachment_file, type: File
      optional :name, type: String
      optional :description, type: String
      requires :path, type: String
      requires :behavior, type: String
    end
    post "/api/rest/v1/behaviors" do
      status 201
      { "id" => 1, "path" => "example", "attachment_url" => "example", "behavior" => "webhook", "name" => "example", "description" => "example", "value" => { "key" => "example value" } }
    end

    params do
      requires :url, type: String
      optional :method, type: String
      optional :encoding, type: String
      optional :headers, type: Hash
      optional :body, type: Hash
      optional :action, type: String
    end
    post "/api/rest/v1/behaviors/webhook/test" do
      status 200
      body false
    end

    params do
      requires :id, type: [ String, Integer, Hash ]
      optional :value, type: String
      optional :attachment_file, type: File
      optional :name, type: String
      optional :description, type: String
      optional :behavior, type: String
      optional :path, type: String
      optional :attachment_delete, type: [ String, Integer, Hash ]
    end
    patch "/api/rest/v1/behaviors/:id" do
      status 200
      { "id" => 1, "path" => "example", "attachment_url" => "example", "behavior" => "webhook", "name" => "example", "description" => "example", "value" => { "key" => "example value" } }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/behaviors/:id" do
      status 204
      body false
    end
  end
end
