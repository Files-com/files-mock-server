module FilesMockServer
  class LockAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :path, type: String
      optional :include_children, type: Boolean
    end
    get "/api/rest/v1/locks/:path" do
      status 200
      [ { "path" => "locked_file", "timeout" => 43200, "depth" => "infinity", "recursive" => true, "owner" => "user", "scope" => "shared", "exclusive" => true, "token" => "17c54824e9931a4688ca032d03f6663c", "type" => "write", "allow_access_by_any_user" => true, "user_id" => 1, "username" => "" } ]
    end

    params do
      requires :path, type: String
      optional :allow_access_by_any_user, type: Boolean
      optional :exclusive, type: Boolean
      optional :recursive, type: String
      optional :timeout, type: Integer
    end
    post "/api/rest/v1/locks/:path" do
      status 201
      { "path" => "locked_file", "timeout" => 43200, "depth" => "infinity", "recursive" => true, "owner" => "user", "scope" => "shared", "exclusive" => true, "token" => "17c54824e9931a4688ca032d03f6663c", "type" => "write", "allow_access_by_any_user" => true, "user_id" => 1, "username" => "" }
    end

    params do
      requires :path, type: String
      requires :token, type: String
    end
    delete "/api/rest/v1/locks/:path" do
      status 204
      body false
    end
  end
end
