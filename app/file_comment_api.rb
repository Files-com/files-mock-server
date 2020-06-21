module FilesMockServer
  class FileCommentAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      requires :path, type: String
    end
    get "/file_comments/files/*path" do
      status 200
      [{"id"=>1, "body"=>"What a great file!", "reactions"=>[]}]
    end

    params do
      requires :body, type: String
      requires :path, type: String
    end
    post "/file_comments" do
      status 201
      {"id"=>1, "body"=>"What a great file!", "reactions"=>[]}
    end

    params do
      requires :id, type: Integer
      requires :body, type: String
    end
    patch "/file_comments/:id" do
      status 200
      {"id"=>1, "body"=>"What a great file!", "reactions"=>[]}
    end

    params do
      requires :id, type: Integer
    end
    delete "/file_comments/:id" do
      status 204
      body false
    end
  end
end
