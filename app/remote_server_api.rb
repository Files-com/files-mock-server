module FilesMockServer
  class RemoteServerAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/remote_servers" do
      status 200
      [ { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "upload_staging_path" => "/tmp/uploads", "allow_relative_paths" => true, "name" => "My Remote server", "description" => "More information or notes about my server", "port" => 1, "buffer_uploads" => "example", "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "remote_server_credential_id" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "s3_assume_role_arn" => "example", "s3_assume_role_duration_seconds" => 1, "s3_assume_role_external_id" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "workspace_id" => 1, "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_authentication_method" => "json", "google_cloud_storage_oauth_scope" => "https://www.googleapis.com/auth/devstorage.read_only", "google_cloud_storage_project_id" => "my-project", "google_cloud_storage_s3_compatible_access_key" => "example", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_blob_storage_dns_suffix" => "usgovcloudapi.net", "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "azure_files_storage_dns_suffix" => "file.core.windows.net", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_virtual_hosted_style" => true, "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "files_agent_up_to_date" => true, "files_agent_latest_version" => "example", "files_agent_supports_push_updates" => true, "outbound_agent_id" => 1, "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "files_api_key_prefix" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id/ping_agent" do
      status 200
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "upload_staging_path" => "/tmp/uploads", "allow_relative_paths" => true, "name" => "My Remote server", "description" => "More information or notes about my server", "port" => 1, "buffer_uploads" => "example", "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "remote_server_credential_id" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "s3_assume_role_arn" => "example", "s3_assume_role_duration_seconds" => 1, "s3_assume_role_external_id" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "workspace_id" => 1, "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_authentication_method" => "json", "google_cloud_storage_oauth_scope" => "https://www.googleapis.com/auth/devstorage.read_only", "google_cloud_storage_project_id" => "my-project", "google_cloud_storage_s3_compatible_access_key" => "example", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_blob_storage_dns_suffix" => "usgovcloudapi.net", "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "azure_files_storage_dns_suffix" => "file.core.windows.net", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_virtual_hosted_style" => true, "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "files_agent_up_to_date" => true, "files_agent_latest_version" => "example", "files_agent_supports_push_updates" => true, "outbound_agent_id" => 1, "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "files_api_key_prefix" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "upload_staging_path" => "/tmp/uploads", "allow_relative_paths" => true, "name" => "My Remote server", "description" => "More information or notes about my server", "port" => 1, "buffer_uploads" => "example", "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "remote_server_credential_id" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "s3_assume_role_arn" => "example", "s3_assume_role_duration_seconds" => 1, "s3_assume_role_external_id" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "workspace_id" => 1, "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_authentication_method" => "json", "google_cloud_storage_oauth_scope" => "https://www.googleapis.com/auth/devstorage.read_only", "google_cloud_storage_project_id" => "my-project", "google_cloud_storage_s3_compatible_access_key" => "example", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_blob_storage_dns_suffix" => "usgovcloudapi.net", "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "azure_files_storage_dns_suffix" => "file.core.windows.net", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_virtual_hosted_style" => true, "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "files_agent_up_to_date" => true, "files_agent_latest_version" => "example", "files_agent_supports_push_updates" => true, "outbound_agent_id" => 1, "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "files_api_key_prefix" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id/configuration_file" do
      status 200
      { "id" => 1, "permission_set" => "example", "private_key" => "example", "subdomain" => "example", "root" => "C:\\Users\\", "follow_links" => true, "prefer_protocol" => "example", "dns" => "example", "proxy_all_outbound" => true, "endpoint_override" => "example", "log_file" => "example", "log_level" => "example", "log_rotate_num" => 1, "log_rotate_size" => 1, "override_max_concurrent_jobs" => 1, "graceful_shutdown_timeout" => 1, "transfer_rate_limit" => "example", "auto_update_policy" => "example", "api_token" => "example", "port" => 1, "hostname" => "example", "public_key" => "example", "status" => "example", "server_host_key" => "example", "config_version" => "example" }
    end

    params do
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
      optional :reset_authentication, type: Boolean
      optional :ssl_certificate, type: String
      optional :aws_secret_key, type: String
      optional :azure_blob_storage_access_key, type: String
      optional :azure_blob_storage_sas_token, type: String
      optional :azure_files_storage_access_key, type: String
      optional :azure_files_storage_sas_token, type: String
      optional :backblaze_b2_application_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :cloudflare_secret_key, type: String
      optional :filebase_secret_key, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :google_cloud_storage_s3_compatible_secret_key, type: String
      optional :linode_secret_key, type: String
      optional :s3_compatible_secret_key, type: String
      optional :wasabi_secret_key, type: String
      optional :allow_relative_paths, type: Boolean
      optional :aws_access_key, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_blob_storage_container, type: String
      optional :azure_blob_storage_dns_suffix, type: String
      optional :azure_blob_storage_hierarchical_namespace, type: Boolean
      optional :azure_files_storage_account, type: String
      optional :azure_files_storage_dns_suffix, type: String
      optional :azure_files_storage_share_name, type: String
      optional :backblaze_b2_bucket, type: String
      optional :backblaze_b2_s3_endpoint, type: String
      optional :buffer_uploads, type: String
      optional :cloudflare_access_key, type: String
      optional :cloudflare_bucket, type: String
      optional :cloudflare_endpoint, type: String
      optional :description, type: String
      optional :dropbox_teams, type: Boolean
      optional :enable_dedicated_ips, type: Boolean
      optional :filebase_access_key, type: String
      optional :filebase_bucket, type: String
      optional :files_api_key, type: String
      optional :files_agent_permission_set, type: String
      optional :files_agent_root, type: String
      optional :files_agent_version, type: String
      optional :outbound_agent_id, type: Integer
      optional :google_cloud_storage_authentication_method, type: String
      optional :google_cloud_storage_bucket, type: String
      optional :google_cloud_storage_oauth_scope, type: String
      optional :google_cloud_storage_project_id, type: String
      optional :google_cloud_storage_s3_compatible_access_key, type: String
      optional :hostname, type: String
      optional :linode_access_key, type: String
      optional :linode_bucket, type: String
      optional :linode_region, type: String
      optional :max_connections, type: Integer
      optional :name, type: String
      optional :one_drive_account_type, type: String
      optional :pin_to_site_region, type: Boolean
      optional :port, type: Integer
      optional :upload_staging_path, type: String
      optional :remote_server_credential_id, type: Integer
      optional :s3_assume_role_arn, type: String
      optional :s3_assume_role_duration_seconds, type: Integer
      optional :s3_bucket, type: String
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_endpoint, type: String
      optional :s3_compatible_region, type: String
      optional :s3_compatible_virtual_hosted_style, type: Boolean
      optional :s3_region, type: String
      optional :server_certificate, type: String
      optional :server_host_key, type: String
      optional :server_type, type: String
      optional :ssl, type: String
      optional :username, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_bucket, type: String
      optional :wasabi_region, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/remote_servers" do
      status 201
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "upload_staging_path" => "/tmp/uploads", "allow_relative_paths" => true, "name" => "My Remote server", "description" => "More information or notes about my server", "port" => 1, "buffer_uploads" => "example", "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "remote_server_credential_id" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "s3_assume_role_arn" => "example", "s3_assume_role_duration_seconds" => 1, "s3_assume_role_external_id" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "workspace_id" => 1, "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_authentication_method" => "json", "google_cloud_storage_oauth_scope" => "https://www.googleapis.com/auth/devstorage.read_only", "google_cloud_storage_project_id" => "my-project", "google_cloud_storage_s3_compatible_access_key" => "example", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_blob_storage_dns_suffix" => "usgovcloudapi.net", "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "azure_files_storage_dns_suffix" => "file.core.windows.net", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_virtual_hosted_style" => true, "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "files_agent_up_to_date" => true, "files_agent_latest_version" => "example", "files_agent_supports_push_updates" => true, "outbound_agent_id" => 1, "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "files_api_key_prefix" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/remote_servers/:id/agent_push_update" do
      status 200
      { "version" => "example", "message" => "example", "current_version" => "example", "pending_version" => "example", "last_error" => "example", "error" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :proxy_url, type: String
      optional :proxy_host_header, type: String
    end
    post "/api/rest/v1/remote_servers/:id/disconnect_agent" do
      status 200
      { "id" => 1, "nonce" => "example", "status" => "example", "site_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :signed_nonce, type: String
      optional :proxy_registration_refresh, type: Boolean
      optional :agent_version, type: String
      optional :peer_id, type: String
      optional :proxy_url, type: String
      optional :proxy_host_header, type: String
      optional :root, type: String
      optional :agent_hostname, type: String
      optional :downstream_proxy_port, type: Integer
      optional :agent_platform, type: String
      optional :permission_set, type: String
      optional :supports_push_updates, type: Boolean
    end
    post "/api/rest/v1/remote_servers/:id/authenticate_agent" do
      status 200
      { "id" => 1, "nonce" => "example", "status" => "example", "site_id" => 1 }
    end

    params do
      requires :id, type: Integer
      optional :api_token, type: String
      optional :permission_set, type: String
      optional :root, type: String
      optional :hostname, type: String
      optional :port, type: Integer
      optional :status, type: String
      optional :config_version, type: String
      optional :private_key, type: String
      optional :public_key, type: String
      optional :server_host_key, type: String
      optional :subdomain, type: String
    end
    post "/api/rest/v1/remote_servers/:id/configuration_file" do
      status 201
      { "id" => 1, "permission_set" => "example", "private_key" => "example", "subdomain" => "example", "root" => "C:\\Users\\", "follow_links" => true, "prefer_protocol" => "example", "dns" => "example", "proxy_all_outbound" => true, "endpoint_override" => "example", "log_file" => "example", "log_level" => "example", "log_rotate_num" => 1, "log_rotate_size" => 1, "override_max_concurrent_jobs" => 1, "graceful_shutdown_timeout" => 1, "transfer_rate_limit" => "example", "auto_update_policy" => "example", "api_token" => "example", "port" => 1, "hostname" => "example", "public_key" => "example", "status" => "example", "server_host_key" => "example", "config_version" => "example" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/remote_servers/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :azure_blob_storage_access_key, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_blob_storage_container, type: String
      optional :azure_blob_storage_dns_suffix, type: String
      optional :azure_blob_storage_hierarchical_namespace, type: Boolean
      optional :azure_blob_storage_sas_token, type: String
      optional :azure_files_storage_access_key, type: String
      optional :azure_files_storage_account, type: String
      optional :azure_files_storage_dns_suffix, type: String
      optional :azure_files_storage_sas_token, type: String
      optional :azure_files_storage_share_name, type: String
      optional :backblaze_b2_application_key, type: String
      optional :backblaze_b2_bucket, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_s3_endpoint, type: String
      optional :buffer_uploads, type: String
      optional :cloudflare_access_key, type: String
      optional :cloudflare_bucket, type: String
      optional :cloudflare_endpoint, type: String
      optional :cloudflare_secret_key, type: String
      optional :dropbox_teams, type: Boolean
      optional :upload_staging_path, type: String
      optional :enable_dedicated_ips, type: Boolean
      optional :filebase_access_key, type: String
      optional :filebase_bucket, type: String
      optional :filebase_secret_key, type: String
      optional :files_api_key, type: String
      optional :files_agent_api_token, type: String
      optional :files_agent_public_key, type: String
      optional :files_agent_root, type: String
      optional :files_agent_version, type: String
      optional :outbound_agent_id, type: Integer
      optional :google_cloud_storage_authentication_method, type: String
      optional :google_cloud_storage_bucket, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :google_cloud_storage_oauth_scope, type: String
      optional :google_cloud_storage_project_id, type: String
      optional :google_cloud_storage_s3_compatible_access_key, type: String
      optional :google_cloud_storage_s3_compatible_secret_key, type: String
      optional :hostname, type: String
      optional :linode_access_key, type: String
      optional :linode_bucket, type: String
      optional :linode_region, type: String
      optional :linode_secret_key, type: String
      optional :max_connections, type: Integer
      optional :name, type: String
      optional :one_drive_account_type, type: String
      optional :password, type: String
      optional :pin_to_site_region, type: Boolean
      optional :port, type: Integer
      optional :private_key_passphrase, type: String
      optional :private_key, type: String
      optional :remote_server_id, type: Integer
      optional :remote_server_credential_id, type: Integer
      optional :reset_authentication, type: Boolean
      optional :root, type: String
      optional :s3_assume_role_arn, type: String
      optional :s3_assume_role_duration_seconds, type: Integer
      optional :s3_bucket, type: String
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_endpoint, type: String
      optional :s3_compatible_region, type: String
      optional :s3_compatible_virtual_hosted_style, type: Boolean
      optional :s3_compatible_secret_key, type: String
      optional :s3_region, type: String
      optional :server_certificate, type: String
      optional :server_host_key, type: String
      optional :server_type, type: String
      optional :ssl_certificate, type: String
      optional :ssl, type: String
      optional :username, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_bucket, type: String
      optional :wasabi_region, type: String
      optional :wasabi_secret_key, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/remote_servers/list_for_testing" do
      status 200
      { "id" => 1, "path" => "path/file.txt", "path_absolute" => "path/file.txt", "created_by_id" => 1, "created_by_api_key_id" => 1, "created_by_as2_incoming_message_id" => 1, "created_by_automation_id" => 1, "created_by_bundle_registration_id" => 1, "created_by_inbox_id" => 1, "created_by_remote_server_id" => 1, "created_by_sync_id" => 1, "custom_metadata" => { "key" => "value" }, "display_name" => "file.txt", "type" => "file", "size" => 1024, "created_at" => "2000-01-01T01:00:00Z", "last_modified_by_id" => 1, "last_modified_by_api_key_id" => 1, "last_modified_by_automation_id" => 1, "last_modified_by_bundle_registration_id" => 1, "last_modified_by_remote_server_id" => 1, "last_modified_by_sync_id" => 1, "mtime" => "2000-01-01T01:00:00Z", "provided_mtime" => "2000-01-01T01:00:00Z", "crc32" => "70976923", "md5" => "17c54824e9931a4688ca032d03f6663c", "sha1" => "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", "sha256" => "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", "mime_type" => "application/octet-stream", "region" => "us-east-1", "permissions" => "rwd", "subfolders_locked?" => true, "is_locked" => true, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "internal_download_uri" => "example", "download_uri" => "https://mysite.files.com/...", "priority_color" => "red", "preview_id" => 1, "preview" => { "id" => 1, "status" => "complete", "download_uri" => "https://mysite.files.com/...", "type" => "image", "size" => "large" } }
    end

    params do
      requires :id, type: Integer
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
      optional :reset_authentication, type: Boolean
      optional :ssl_certificate, type: String
      optional :aws_secret_key, type: String
      optional :azure_blob_storage_access_key, type: String
      optional :azure_blob_storage_sas_token, type: String
      optional :azure_files_storage_access_key, type: String
      optional :azure_files_storage_sas_token, type: String
      optional :backblaze_b2_application_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :cloudflare_secret_key, type: String
      optional :filebase_secret_key, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :google_cloud_storage_s3_compatible_secret_key, type: String
      optional :linode_secret_key, type: String
      optional :s3_compatible_secret_key, type: String
      optional :wasabi_secret_key, type: String
      optional :allow_relative_paths, type: Boolean
      optional :aws_access_key, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_blob_storage_container, type: String
      optional :azure_blob_storage_dns_suffix, type: String
      optional :azure_blob_storage_hierarchical_namespace, type: Boolean
      optional :azure_files_storage_account, type: String
      optional :azure_files_storage_dns_suffix, type: String
      optional :azure_files_storage_share_name, type: String
      optional :backblaze_b2_bucket, type: String
      optional :backblaze_b2_s3_endpoint, type: String
      optional :buffer_uploads, type: String
      optional :cloudflare_access_key, type: String
      optional :cloudflare_bucket, type: String
      optional :cloudflare_endpoint, type: String
      optional :description, type: String
      optional :dropbox_teams, type: Boolean
      optional :enable_dedicated_ips, type: Boolean
      optional :filebase_access_key, type: String
      optional :filebase_bucket, type: String
      optional :files_api_key, type: String
      optional :files_agent_permission_set, type: String
      optional :files_agent_root, type: String
      optional :files_agent_version, type: String
      optional :outbound_agent_id, type: Integer
      optional :google_cloud_storage_authentication_method, type: String
      optional :google_cloud_storage_bucket, type: String
      optional :google_cloud_storage_oauth_scope, type: String
      optional :google_cloud_storage_project_id, type: String
      optional :google_cloud_storage_s3_compatible_access_key, type: String
      optional :hostname, type: String
      optional :linode_access_key, type: String
      optional :linode_bucket, type: String
      optional :linode_region, type: String
      optional :max_connections, type: Integer
      optional :name, type: String
      optional :one_drive_account_type, type: String
      optional :pin_to_site_region, type: Boolean
      optional :port, type: Integer
      optional :upload_staging_path, type: String
      optional :remote_server_credential_id, type: Integer
      optional :s3_assume_role_arn, type: String
      optional :s3_assume_role_duration_seconds, type: Integer
      optional :s3_bucket, type: String
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_endpoint, type: String
      optional :s3_compatible_region, type: String
      optional :s3_compatible_virtual_hosted_style, type: Boolean
      optional :s3_region, type: String
      optional :server_certificate, type: String
      optional :server_host_key, type: String
      optional :server_type, type: String
      optional :ssl, type: String
      optional :username, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_bucket, type: String
      optional :wasabi_region, type: String
    end
    patch "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "upload_staging_path" => "/tmp/uploads", "allow_relative_paths" => true, "name" => "My Remote server", "description" => "More information or notes about my server", "port" => 1, "buffer_uploads" => "example", "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "remote_server_credential_id" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "s3_assume_role_arn" => "example", "s3_assume_role_duration_seconds" => 1, "s3_assume_role_external_id" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "workspace_id" => 1, "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_authentication_method" => "json", "google_cloud_storage_oauth_scope" => "https://www.googleapis.com/auth/devstorage.read_only", "google_cloud_storage_project_id" => "my-project", "google_cloud_storage_s3_compatible_access_key" => "example", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_blob_storage_dns_suffix" => "usgovcloudapi.net", "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "azure_files_storage_dns_suffix" => "file.core.windows.net", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_virtual_hosted_style" => true, "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "files_agent_up_to_date" => true, "files_agent_latest_version" => "example", "files_agent_supports_push_updates" => true, "outbound_agent_id" => 1, "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "files_api_key_prefix" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/remote_servers/:id" do
      status 204
      body false
    end
  end
end
