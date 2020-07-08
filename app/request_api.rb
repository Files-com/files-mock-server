module FilesMockServer
  class RequestAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :mine, type: Boolean
      optional :path, type: String
    end
    get "/api/rest/v1/requests" do
      status 200
      [ { "id" => 1, "path" => "", "source" => "", "destination" => "", "automation_id" => "", "user_display_name" => "" } ]
    end

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :mine, type: Boolean
      optional :path, type: String
    end
    get "/api/rest/v1/requests/folders/*path" do
      status 200
      [ { "id" => 1, "path" => "", "source" => "", "destination" => "", "automation_id" => "", "user_display_name" => "" } ]
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :user_ids, type: String
      optional :group_ids, type: String
    end
    post "/api/rest/v1/requests" do
      status 201
      { "id" => 1, "path" => "", "source" => "", "destination" => "", "automation_id" => "", "user_display_name" => "" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/requests/:id" do
      status 204
      body false
    end
  end
end
