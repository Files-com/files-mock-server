module FilesMockServer
  class ShareGroupAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/share_groups" do
      status 200
      [ { "id" => 1, "name" => "Test group 1", "notes" => "This group is defined for testing purposes", "user_id" => 1, "members" => [ { "name" => "John Doe", "company" => "Acme Ltd", "email" => "johndoe@gmail.com" } ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/share_groups/:id" do
      status 200
      { "id" => 1, "name" => "Test group 1", "notes" => "This group is defined for testing purposes", "user_id" => 1, "members" => [ { "name" => "John Doe", "company" => "Acme Ltd", "email" => "johndoe@gmail.com" } ] }
    end

    params do
      optional :user_id, type: Integer
      optional :notes, type: String
      requires :name, type: String
      requires :members, type: [ Hash ]
    end
    post "/api/rest/v1/share_groups" do
      status 201
      { "id" => 1, "name" => "Test group 1", "notes" => "This group is defined for testing purposes", "user_id" => 1, "members" => [ { "name" => "John Doe", "company" => "Acme Ltd", "email" => "johndoe@gmail.com" } ] }
    end

    params do
      requires :id, type: Integer
      optional :notes, type: String
      optional :name, type: String
      optional :members, type: [ Hash ]
    end
    patch "/api/rest/v1/share_groups/:id" do
      status 200
      { "id" => 1, "name" => "Test group 1", "notes" => "This group is defined for testing purposes", "user_id" => 1, "members" => [ { "name" => "John Doe", "company" => "Acme Ltd", "email" => "johndoe@gmail.com" } ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/share_groups/:id" do
      status 204
      body false
    end
  end
end
