module FilesMockServer
  class StyleAPI < Grape::API
    format :json

    params do
      requires :path, type: String
    end
    get "/styles/*path" do
      status 200
      { "id" => 1, "path" => "", "logo" => "", "thumbnail" => "" }
    end

    params do
      requires :path, type: String
      requires :file, type: File
    end
    patch "/styles/*path" do
      status 200
      { "id" => 1, "path" => "", "logo" => "", "thumbnail" => "" }
    end

    params do
      requires :path, type: String
    end
    delete "/styles/*path" do
      status 204
      body false
    end
  end
end
