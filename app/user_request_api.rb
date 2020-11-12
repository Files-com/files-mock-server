module FilesMockServer
  class UserRequestAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_requests" do
      status 200
      [ { "id" => 1, "name" => "John Doe", "email" => "john.doe@files.com", "details" => "Changed Departments" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/user_requests/:id" do
      status 200
      { "id" => 1, "name" => "John Doe", "email" => "john.doe@files.com", "details" => "Changed Departments" }
    end

    params do
      requires :name, type: String
      requires :email, type: String
      requires :details, type: String
    end
    post "/api/rest/v1/user_requests" do
      status 201
      { "id" => 1, "name" => "John Doe", "email" => "john.doe@files.com", "details" => "Changed Departments" }
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
