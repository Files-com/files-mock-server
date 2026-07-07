module FilesMockServer
  class ReleaseAPI < Grape::API
    format :json

    params do
      optional :product, type: String
      optional :platform, type: String
      optional :architecture, type: String
      optional :ext, type: String
    end
    get "/api/rest/v1/releases/latest" do
      status 200
      { "version" => "1.0.0", "description" => "The initial release of Files.com Desktop", "native_release_packages" => [ { "package_link" => "https://www.files.com/desktop/download", "platform" => "win32", "architecture" => "amd64", "extension" => "deb", "sha256" => "example" } ], "title" => "Files.com", "product" => "desktop_v4" }
    end

    params do
      optional :title, type: String
      optional :description, type: String
      optional :version_major, type: Integer
      optional :version_minor, type: Integer
      optional :version_patch, type: Integer
      optional :version_build, type: Integer
      optional :oem, type: String
      optional :product, type: String
      optional :native_release_packages, type: [ Hash ]
    end
    post "/api/rest/v1/releases" do
      status 201
      { "version" => "1.0.0", "description" => "The initial release of Files.com Desktop", "native_release_packages" => [ { "package_link" => "https://www.files.com/desktop/download", "platform" => "win32", "architecture" => "amd64", "extension" => "deb", "sha256" => "example" } ], "title" => "Files.com", "product" => "desktop_v4" }
    end
  end
end
