module FilesMockServer
  class MessageCommentReactionAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      requires :message_comment_id, type: Integer
    end
    get "/api/rest/v1/message_comment_reactions" do
      status 200
      [ { "id" => 1, "emoji" => "👍" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/message_comment_reactions/:id" do
      status 200
      { "id" => 1, "emoji" => "👍" }
    end

    params do
      optional :user_id, type: Integer
      requires :emoji, type: String
    end
    post "/api/rest/v1/message_comment_reactions" do
      status 201
      { "id" => 1, "emoji" => "👍" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/message_comment_reactions/:id" do
      status 204
      body false
    end
  end
end
