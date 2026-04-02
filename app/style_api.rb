module FilesMockServer
  class StyleAPI < Grape::API
    format :json

    params do
      requires :path, type: String
    end
    get "/api/rest/v1/styles/:path" do
      status 200
      { "id" => 1, "path" => "example", "logo" => "https://mysite.files.com/...", "logo_click_href" => "https://www.example.com", "thumbnail" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" } }
    end

    params do
      requires :path, type: String
      optional :file, type: File
      optional :logo_click_href, type: String
    end
    patch "/api/rest/v1/styles/:path" do
      status 200
      { "id" => 1, "path" => "example", "logo" => "https://mysite.files.com/...", "logo_click_href" => "https://www.example.com", "thumbnail" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" } }
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
