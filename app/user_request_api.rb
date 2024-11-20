module FilesMockServer
  class UserRequestAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_requests" do
      status 200
      [ { "id" => 1, "name" => "John Doe", "email" => "example", "details" => "Changed Departments", "company" => "Acme Inc." } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_requests/:id" do
      status 200
      { "id" => 1, "name" => "John Doe", "email" => "example", "details" => "Changed Departments", "company" => "Acme Inc." }
    end

    params do
      requires :name, type: String
      requires :email, type: String
      requires :details, type: String
      optional :company, type: String
    end
    post "/api/rest/v1/user_requests" do
      status 201
      { "id" => 1, "name" => "John Doe", "email" => "example", "details" => "Changed Departments", "company" => "Acme Inc." }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    post "/api/rest/v1/user_requests/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/user_requests/:id" do
      status 204
      body false
    end
  end
end
