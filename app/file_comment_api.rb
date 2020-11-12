module FilesMockServer
  class FileCommentAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :path, type: String
    end
    get "/api/rest/v1/file_comments/files/:path" do
      status 200
      [ { "id" => 1, "body" => "What a great file!", "reactions" => [] } ]
    end

    params do
      requires :body, type: String
      requires :path, type: String
    end
    post "/api/rest/v1/file_comments" do
      status 201
      { "id" => 1, "body" => "What a great file!", "reactions" => [] }
    end

    params do
      requires :id, type: Integer
      requires :body, type: String
    end
    patch "/api/rest/v1/file_comments/:id" do
      status 200
      { "id" => 1, "body" => "What a great file!", "reactions" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/file_comments/:id" do
      status 204
      body false
    end
  end
end
