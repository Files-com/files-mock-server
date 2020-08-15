module FilesMockServer
  class MessageCommentAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      requires :message_id, type: Integer
    end
    get "/api/rest/v1/message_comments" do
      status 200
      [ { "id" => 1, "body" => "What a great idea, thank you!", "reactions" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/message_comments/:id" do
      status 200
      { "id" => 1, "body" => "What a great idea, thank you!", "reactions" => [] }
    end

    params do
      optional :user_id, type: Integer
      requires :body, type: String
    end
    post "/api/rest/v1/message_comments" do
      status 201
      { "id" => 1, "body" => "What a great idea, thank you!", "reactions" => [] }
    end

    params do
      requires :id, type: Integer
      requires :body, type: String
    end
    patch "/api/rest/v1/message_comments/:id" do
      status 200
      { "id" => 1, "body" => "What a great idea, thank you!", "reactions" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/message_comments/:id" do
      status 204
      body false
    end
  end
end
