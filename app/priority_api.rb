module FilesMockServer
  class PriorityAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      requires :path, type: String
    end
    get "/api/rest/v1/priorities" do
      status 200
      [ { "path" => "foo/bar", "color" => "pink" } ]
    end
  end
end
