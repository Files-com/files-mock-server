module FilesMockServer
  class UserAdditionalEmailRecipientAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/user_additional_email_recipients" do
      status 200
      [ { "id" => 1, "user_id" => 1, "workspace_id" => 1, "email" => "user-copy@example.com", "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :user_id, type: Integer
      requires :email, type: String
    end
    post "/api/rest/v1/user_additional_email_recipients" do
      status 201
      { "id" => 1, "user_id" => 1, "workspace_id" => 1, "email" => "user-copy@example.com", "created_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_additional_email_recipients/:id" do
      status 200
      { "id" => 1, "user_id" => 1, "workspace_id" => 1, "email" => "user-copy@example.com", "created_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :email, type: String
    end
    patch "/api/rest/v1/user_additional_email_recipients/:id" do
      status 200
      { "id" => 1, "user_id" => 1, "workspace_id" => 1, "email" => "user-copy@example.com", "created_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/user_additional_email_recipients/:id" do
      status 204
      body false
    end
  end
end
