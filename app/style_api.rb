module FilesMockServer
  class StyleAPI < Grape::API
    format :json

    params do
      requires :path, type: String
    end
    get "/api/rest/v1/styles/:path" do
      status 200
      { "id" => 1, "path" => "example", "logo" => "https://mysite.files.com/...", "thumbnail" => "example" }
    end

    params do
      requires :path, type: String
      requires :file, type: File
    end
    patch "/api/rest/v1/styles/:path" do
      status 200
      { "id" => 1, "path" => "example", "logo" => "https://mysite.files.com/...", "thumbnail" => "example" }
    end

    params do
      requires :path, type: String
    end
    delete "/api/rest/v1/styles/:path" do
      status 204
      body false
    end
  end
end
