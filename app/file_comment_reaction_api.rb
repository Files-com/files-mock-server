module FilesMockServer
  class FileCommentReactionAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      requires :file_comment_id, type: Integer
      requires :emoji, type: String
    end
    post "/file_comment_reactions" do
      status 201
      { "id" => 1, "emoji" => "👍" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/file_comment_reactions/:id" do
      status 204
      body false
    end
  end
end
