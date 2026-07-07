module FilesMockServer
  class AiAssistantPersonalityAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/ai_assistant_personalities" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Concise Assistant", "system_prompt" => "Respond as a concise operations assistant.", "use_by_default" => true, "apply_to_all_workspaces" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/ai_assistant_personalities/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Concise Assistant", "system_prompt" => "Respond as a concise operations assistant.", "use_by_default" => true, "apply_to_all_workspaces" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :apply_to_all_workspaces, type: Boolean
      requires :name, type: String
      requires :system_prompt, type: String
      optional :use_by_default, type: Boolean
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/ai_assistant_personalities" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Concise Assistant", "system_prompt" => "Respond as a concise operations assistant.", "use_by_default" => true, "apply_to_all_workspaces" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/ai_assistant_personalities/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :apply_to_all_workspaces, type: Boolean
      optional :name, type: String
      optional :system_prompt, type: String
      optional :use_by_default, type: Boolean
      optional :workspace_id, type: Integer
    end
    patch "/api/rest/v1/ai_assistant_personalities/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Concise Assistant", "system_prompt" => "Respond as a concise operations assistant.", "use_by_default" => true, "apply_to_all_workspaces" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/ai_assistant_personalities/:id" do
      status 204
      body false
    end
  end
end
