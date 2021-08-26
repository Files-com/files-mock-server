module FilesMockServer
  class BehaviorAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :behavior, type: String
    end
    get "/api/rest/v1/behaviors" do
      status 200
      [ { "id" => 1, "path" => "", "attachment_url" => "", "behavior" => "webhook", "name" => "", "description" => "", "value" => { "method" => "GET" } } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/behaviors/:id" do
      status 200
      { "id" => 1, "path" => "", "attachment_url" => "", "behavior" => "webhook", "name" => "", "description" => "", "value" => { "method" => "GET" } }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      requires :path, type: String
      optional :recursive, type: String
      optional :behavior, type: String
    end
    get "/api/rest/v1/behaviors/folders/:path" do
      status 200
      [ { "id" => 1, "path" => "", "attachment_url" => "", "behavior" => "webhook", "name" => "", "description" => "", "value" => { "method" => "GET" } } ]
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
      { "id" => 1, "path" => "", "attachment_url" => "", "behavior" => "webhook", "name" => "", "description" => "", "value" => { "method" => "GET" } }
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
      optional :path, type: [ String, Integer, Hash ]
    end
    patch "/api/rest/v1/behaviors/:id" do
      status 200
      { "id" => 1, "path" => "", "attachment_url" => "", "behavior" => "webhook", "name" => "", "description" => "", "value" => { "method" => "GET" } }
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
