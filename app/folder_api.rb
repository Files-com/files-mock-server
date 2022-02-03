module FilesMockServer
  class FolderAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :path, type: String
      optional :filter, type: String
      optional :preview_size, type: String
      optional :search, type: String
      optional :search_all, type: Boolean
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
    end
    get "/api/rest/v1/folders/:path" do
      status 200
      [ { "path" => "path/file.txt", "display_name" => "file.txt", "type" => "file", "size" => 1024, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "complete", "size" => 1024 } } ]
    end

    params do
      requires :path, type: String
    end
    post "/api/rest/v1/folders/:path" do
      status 201
      { "path" => "path/file.txt", "display_name" => "file.txt", "type" => "file", "size" => 1024, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "complete", "size" => 1024 } }
    end
  end
end
