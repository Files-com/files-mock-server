module FilesMockServer
  class ChatSessionAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/chat_sessions" do
      status 200
      [ { "id" => "example", "user_id" => 1, "ai_task_id" => 1, "workspace_id" => 1, "last_active_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "messages" => [ { "id" => 1, "role" => "example", "content" => "example", "created_at" => "2000-01-01T01:00:00Z" } ] } ]
    end

    params do
      requires :id, type: String
    end
    get "/api/rest/v1/chat_sessions/:id" do
      status 200
      { "id" => "example", "user_id" => 1, "ai_task_id" => 1, "workspace_id" => 1, "last_active_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "messages" => [ { "id" => 1, "role" => "example", "content" => "example", "created_at" => "2000-01-01T01:00:00Z" } ] }
    end
  end
end
