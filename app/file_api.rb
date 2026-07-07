module FilesMockServer
  class FileAPI < Grape::API
    format :json

    params do
      requires :path, type: String
      optional :action, type: String
      optional :bundle_registration_code, type: String
      optional :prefer_spdy, type: Boolean
      optional :preview_size, type: String
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
      optional :full_document_preview, type: Boolean
    end
    get "/api/rest/v1/files/:path" do
      status 200
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :copy_destination, type: String
      optional :move_destination, type: String
      optional :action, type: String
      optional :action_attributes, type: Hash
      optional :file, type: Hash
      optional :crc32, type: String
      optional :crc32b, type: String
      optional "etags[etag]", type: [ String ]
      optional "etags[part]", type: [ Integer ]
      optional :length, type: Integer
      optional :md5, type: String
      optional :mkdir_parents, type: Boolean
      optional :overwrite, type: Boolean
      optional :part, type: Integer
      optional :parts, type: Integer
      optional :prefer_spdy, type: Boolean
      optional :provided_mtime, type: String
      optional :ref, type: String
      optional :restart, type: Integer
      optional :sha1, type: String
      optional :sha256, type: String
      optional :size, type: Integer
      optional :copy_behaviors, type: Boolean
      optional :structure, type: String
      optional :with_rename, type: Boolean
      optional :inbox_registration_code, type: String
      optional :bundle_registration_code, type: String
      optional :buffered_upload, type: Boolean
    end
    post "/api/rest/v1/files/:path" do
      status 201
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :custom_metadata, type: Hash
      optional :provided_mtime, type: String
      optional :priority_color, type: String
    end
    patch "/api/rest/v1/files/:path" do
      status 200
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :recursive, type: Boolean
      optional :bundle_registration_code, type: String
    end
    delete "/api/rest/v1/files/:path" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :preview_size, type: String
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
    end
    get "/api/rest/v1/file_actions/id/:id" do
      status 200
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :path, type: String
      optional :preview_size, type: String
      optional :with_previews, type: Boolean
      optional :with_priority_color, type: Boolean
      optional :bundle_registration_code, type: String
    end
    get "/api/rest/v1/file_actions/metadata/:path" do
      status 200
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
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
      optional :copy_behaviors, type: Boolean
      optional :structure, type: Boolean
      optional :overwrite, type: Boolean
      optional :bundle_registration_code, type: String
    end
    post "/api/rest/v1/file_actions/copy/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :overwrite, type: Boolean
      optional :bundle_registration_code, type: String
    end
    post "/api/rest/v1/file_actions/move/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      requires :transform_type, type: String
      requires :target_format, type: String
      optional :script, type: String
      optional :width, type: Integer
      optional :height, type: Integer
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/transform/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :gpg_key_ids, type: [ Integer ]
      optional :gpg_key_partner_id, type: Integer
      optional :use_all_private_keys, type: Boolean
      optional :ignore_mdc_error, type: Boolean
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/gpg_decrypt/:path" do
      status 201
      { "status" => "pending", "file_migration_id" => 1 }
    end

    params do
      requires :path, type: String
      requires :destination, type: String
      optional :gpg_key_ids, type: [ Integer ]
      optional :gpg_key_partner_id, type: Integer
      optional :signing_key_id, type: Integer
      optional :armor, type: Boolean
      optional :overwrite, type: Boolean
    end
    post "/api/rest/v1/file_actions/gpg_encrypt/:path" do
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
      optional :prefer_spdy, type: Boolean
      optional :ref, type: String
      optional :restart, type: Integer
      optional :size, type: Integer
      optional :with_rename, type: Boolean
      optional :action, type: String
      optional :bundle_registration_code, type: String
      optional :buffered_upload, type: Boolean
    end
    post "/api/rest/v1/file_actions/begin_upload/:path" do
      status 200
      [ { "send" => { "key" => "example value" }, "action" => "multipart", "ask_about_overwrites" => true, "available_parts" => 1, "expires" => "example", "headers" => { "key" => "example value" }, "http_method" => "PUT", "next_partsize" => 1, "parallel_parts" => true, "retry_parts" => true, "parameters" => { "key" => "example value" }, "part_number" => 1, "partsize" => 1, "path" => "", "ref" => "upload-1", "upload_uri" => "example", "internal_upload_uri" => "example" } ]
    end
  end
end
