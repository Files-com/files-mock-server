module FilesMockServer
  class FileActionAPI < Grape::API
    format :json

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :structure, type: Boolean
    end
    post "/api/rest/v1/file_actions/copy/:path" do
      status 204
      body false
    end

    params do
      requires :path, type: String
      requires :destination, type: String
    end
    post "/api/rest/v1/file_actions/move/:path" do
      status 204
      body false
    end

    params do
      requires :path, type: String
      optional :mkdir_parents, type: Boolean
      optional :part, type: Integer
      optional :parts, type: Integer
      optional :ref, type: String
      optional :restart, type: Integer
      optional :with_rename, type: Boolean
    end
    post "/api/rest/v1/file_actions/begin_upload/:path" do
      status 200
      [ { "send" => "", "action" => "multipart", "ask_about_overwrites" => true, "available_parts" => 1, "expires" => "", "headers" => "", "http_method" => "PUT", "next_partsize" => 1, "parallel_parts" => true, "parameters" => "{}", "part_number" => 1, "partsize" => 1, "path" => "", "ref" => "upload-1", "upload_uri" => "" } ]
    end
  end
end
