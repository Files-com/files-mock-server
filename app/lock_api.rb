module FilesMockServer
  class LockAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      requires :path, type: String
      optional :include_children, type: Boolean
    end
    get "/api/rest/v1/locks/*path" do
      status 200
      [ { "path" => "locked_file", "timeout" => 43200, "depth" => "infinity", "owner" => "user", "scope" => "shared", "token" => "17c54824e9931a4688ca032d03f6663c", "type" => "write", "user_id" => 1, "username" => "username" } ]
    end

    params do
      requires :path, type: String
      optional :timeout, type: Integer
    end
    post "/api/rest/v1/locks/*path" do
      status 201
      { "path" => "locked_file", "timeout" => 43200, "depth" => "infinity", "owner" => "user", "scope" => "shared", "token" => "17c54824e9931a4688ca032d03f6663c", "type" => "write", "user_id" => 1, "username" => "username" }
    end

    params do
      requires :path, type: String
      requires :token, type: String
    end
    delete "/api/rest/v1/locks/*path" do
      status 204
      body false
    end
  end
end
