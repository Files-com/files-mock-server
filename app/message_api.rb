module FilesMockServer
  class MessageAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      requires :project_id, type: Integer
    end
    get "/api/rest/v1/messages" do
      status 200
      [ { "id" => 1, "subject" => "Files.com Account Upgrade", "body" => "We should upgrade our Files.com account!", "comments" => [] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/messages/:id" do
      status 200
      { "id" => 1, "subject" => "Files.com Account Upgrade", "body" => "We should upgrade our Files.com account!", "comments" => [] }
    end

    params do
      optional :user_id, type: Integer
      requires :project_id, type: Integer
      requires :subject, type: String
      requires :body, type: String
    end
    post "/api/rest/v1/messages" do
      status 201
      { "id" => 1, "subject" => "Files.com Account Upgrade", "body" => "We should upgrade our Files.com account!", "comments" => [] }
    end

    params do
      requires :id, type: Integer
      requires :project_id, type: Integer
      requires :subject, type: String
      requires :body, type: String
    end
    patch "/api/rest/v1/messages/:id" do
      status 200
      { "id" => 1, "subject" => "Files.com Account Upgrade", "body" => "We should upgrade our Files.com account!", "comments" => [] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/messages/:id" do
      status 204
      body false
    end
  end
end
