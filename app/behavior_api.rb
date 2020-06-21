module FilesMockServer
  class BehaviorAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :behavior, type: String
    end
    get "/behaviors" do
      status 200
      [{"id"=>1, "path"=>"", "attachment_url"=>"", "behavior"=>"webhook", "value"=>{"method"=>"GET"}}]
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      requires :path, type: String
      optional :recursive, type: String
      optional :behavior, type: String
    end
    get "/behaviors/folders/*path" do
      status 200
      [{"id"=>1, "path"=>"", "attachment_url"=>"", "behavior"=>"webhook", "value"=>{"method"=>"GET"}}]
    end

    params do
      requires :id, type: Integer
    end
    get "/behaviors/:id" do
      status 200
      {"id"=>1, "path"=>"", "attachment_url"=>"", "behavior"=>"webhook", "value"=>{"method"=>"GET"}}
    end

    params do
      optional :value, type: String
      optional :attachment_file, type: File
      requires :path, type: String
      requires :behavior, type: String
    end
    post "/behaviors" do
      status 201
      {"id"=>1, "path"=>"", "attachment_url"=>"", "behavior"=>"webhook", "value"=>{"method"=>"GET"}}
    end

    params do
      requires :url, type: String
      optional :method, type: String
      optional :encoding, type: String
      optional :headers, type: Hash
      optional :body, type: Hash
    end
    post "/behaviors/webhook/test" do
      status 200
      body false
    end

    params do
      requires :id, type: [String, Integer, Hash]
      optional :value, type: String
      optional :attachment_file, type: [String, Integer, Hash]
    end
    patch "/behaviors/:id" do
      status 200
      {"id"=>1, "path"=>"", "attachment_url"=>"", "behavior"=>"webhook", "value"=>{"method"=>"GET"}}
    end

    params do
      requires :id, type: Integer
    end
    delete "/behaviors/:id" do
      status 204
      body false
    end
  end
end
