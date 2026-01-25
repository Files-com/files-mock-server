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
      { "path" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :action, type: String
      optional "etags[etag]", type: [ String ]
      optional "etags[part]", type: [ Integer ]
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
      optional :buffered_upload, type: Boolean
    end
    post "/api/rest/v1/files/:path" do
      status 201
      { "path" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :custom_metadata, type: Hash
      optional :provided_mtime, type: String
      optional :priority_color, type: String
    end
    patch "/api/rest/v1/files/:path" do
      status 200
      { "path" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :recursive, type: Boolean
    end
    delete "/api/rest/v1/files/:path" do
      status 204
      body false
    end

    params do
      requires :path, type: String
      optional :preview_size, type: String
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
    end
    get "/api/rest/v1/file_actions/metadata/:path" do
      status 200
      { "path" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
    end
    get "/api/rest/v1/file_actions/zip_list/:path" do
      status 200
      [ { "path" => "example", "size" => 1 } ]
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :structure, type: Boolean
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/copy/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/move/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :filename, type: String
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/unzip" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :paths, type: [ String ]
      requires :destination, type: String
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/zip" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      optional :mkdir_parents, type: Boolean
      optional :part, type: Integer
      optional :parts, type: Integer
      optional :ref, type: String
      optional :restart, type: Integer
      optional :size, type: Integer
      optional :with_rename, type: Boolean
    end
    post "/api/rest/v1/file_actions/begin_upload/:path" do
      status 200
      [ { "send" => { "key" => "example value" }, "action" => "multipart", "ask_about_overwrites" => true, "available_parts" => 1, "expires" => "example", "headers" => { "key" => "example value" }, "http_method" => "PUT", "next_partsize" => 1, "parallel_parts" => true, "retry_parts" => true, "parameters" => { "key" => "example value" }, "part_number" => 1, "partsize" => 1, "path" => "", "ref" => "upload-1", "upload_uri" => "example" } ]
    end
  end
end
