module FilesMockServer
  class FileActionAPI < Grape::API
    format :json

    params do
      requires :path, type: String
      requires :destination, type: String
    end
    post "/file_actions/copy/*path" do
      status 204
      body false
    end

    params do
      requires :path, type: String
      requires :destination, type: String
    end
    post "/file_actions/move/*path" do
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
    post "/file_actions/begin_upload/*path" do
      status 200
      [ { "send" => "", "action" => "upload/direct", "ask_about_overwrites" => true, "available_parts" => "", "expires" => "", "headers" => "", "http_method" => "POST", "next_partsize" => "", "parameters" => "", "part_number" => "", "partsize" => "", "path" => "path", "ref" => "upload-1", "upload_uri" => "" } ]
    end
  end
end
