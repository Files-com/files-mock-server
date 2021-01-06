module FilesMockServer
  class FileAPI < Grape::API
    format :json

    params do
      requires :path, type: String
      optional :action, type: String
      optional :preview_size, type: String
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
    end
    get "/api/rest/v1/files/:path" do
      status 200
      { "path" => "path/file.txt", "display_name" => "file.txt", "type" => "file", "size" => 1024, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rpw", "subfolders_locked?" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "complete", "size" => 1024 } }
    end

    params do
      requires :path, type: String
      optional :action, type: String
      optional "etags[etag]", type: Array[String]
      optional "etags[part]", type: Array[Integer]
      optional :length, type: Integer
      optional :mkdir_parents, type: Boolean
      optional :part, type: Integer
      optional :parts, type: Integer
      optional :provided_mtime, type: String
      optional :ref, type: String
      optional :restart, type: Integer
      optional :size, type: Integer
      optional :structure, type: String
      optional :with_rename, type: Boolean
    end
    post "/api/rest/v1/files/:path" do
      status 201
      { "path" => "path/file.txt", "display_name" => "file.txt", "type" => "file", "size" => 1024, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rpw", "subfolders_locked?" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "complete", "size" => 1024 } }
    end

    params do
      requires :path, type: String
      optional :provided_mtime, type: String
      optional :priority_color, type: String
    end
    patch "/api/rest/v1/files/:path" do
      status 200
      { "path" => "path/file.txt", "display_name" => "file.txt", "type" => "file", "size" => 1024, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rpw", "subfolders_locked?" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "complete", "size" => 1024 } }
    end

    params do
      requires :path, type: String
      optional :recursive, type: Boolean
    end
    delete "/api/rest/v1/files/:path" do
      status 204
      body false
    end
  end
end
