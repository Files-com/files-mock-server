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
      [ { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id/configuration_file" do
      status 200
      { "id" => 1, "permission_set" => "example", "private_key" => "example", "subdomain" => "example", "root" => "C:\\Users\\", "follow_links" => true, "prefer_protocol" => "example", "dns" => "example", "proxy_all_outbound" => true, "endpoint_override" => "example", "log_file" => "example", "log_level" => "example", "log_rotate_num" => 1, "log_rotate_size" => 1, "override_max_concurrent_jobs" => 1, "graceful_shutdown_timeout" => 1, "transfer_rate_limit" => "example", "api_token" => "example", "port" => 1, "hostname" => "example", "public_key" => "example", "status" => "example", "server_host_key" => "example", "config_version" => "example" }
    end

    params do
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
      optional :ssl_certificate, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
      optional :azure_blob_storage_access_key, type: String
      optional :azure_files_storage_access_key, type: String
      optional :hostname, type: String
      optional :name, type: String
      optional :max_connections, type: Integer
      optional :pin_to_site_region, type: Boolean
      optional :port, type: Integer
      optional :s3_bucket, type: String
      optional :s3_region, type: String
      optional :server_certificate, type: String
      optional :server_host_key, type: String
      optional :server_type, type: String
      optional :ssl, type: String
      optional :username, type: String
      optional :google_cloud_storage_bucket, type: String
      optional :google_cloud_storage_project_id, type: String
      optional :backblaze_b2_bucket, type: String
      optional :backblaze_b2_s3_endpoint, type: String
      optional :wasabi_bucket, type: String
      optional :wasabi_region, type: String
      optional :rackspace_username, type: String
      optional :rackspace_region, type: String
      optional :rackspace_container, type: String
      optional :one_drive_account_type, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_blob_storage_container, type: String
      optional :azure_blob_storage_hierarchical_namespace, type: Boolean
      optional :azure_blob_storage_sas_token, type: String
      optional :azure_files_storage_account, type: String
      optional :azure_files_storage_share_name, type: String
      optional :azure_files_storage_sas_token, type: String
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_endpoint, type: String
      optional :s3_compatible_region, type: String
      optional :enable_dedicated_ips, type: Boolean
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_secret_key, type: String
      optional :files_agent_root, type: String
      optional :files_agent_permission_set, type: String
      optional :files_agent_version, type: String
      optional :filebase_access_key, type: String
      optional :filebase_secret_key, type: String
      optional :filebase_bucket, type: String
      optional :cloudflare_access_key, type: String
      optional :cloudflare_secret_key, type: String
      optional :cloudflare_bucket, type: String
      optional :cloudflare_endpoint, type: String
      optional :dropbox_teams, type: Boolean
      optional :linode_access_key, type: String
      optional :linode_secret_key, type: String
      optional :linode_bucket, type: String
      optional :linode_region, type: String
    end
    post "/api/rest/v1/remote_servers" do
      status 201
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
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
      { "id" => 1, "permission_set" => "example", "private_key" => "example", "subdomain" => "example", "root" => "C:\\Users\\", "follow_links" => true, "prefer_protocol" => "example", "dns" => "example", "proxy_all_outbound" => true, "endpoint_override" => "example", "log_file" => "example", "log_level" => "example", "log_rotate_num" => 1, "log_rotate_size" => 1, "override_max_concurrent_jobs" => 1, "graceful_shutdown_timeout" => 1, "transfer_rate_limit" => "example", "api_token" => "example", "port" => 1, "hostname" => "example", "public_key" => "example", "status" => "example", "server_host_key" => "example", "config_version" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
      optional :ssl_certificate, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
      optional :azure_blob_storage_access_key, type: String
      optional :azure_files_storage_access_key, type: String
      optional :hostname, type: String
      optional :name, type: String
      optional :max_connections, type: Integer
      optional :pin_to_site_region, type: Boolean
      optional :port, type: Integer
      optional :s3_bucket, type: String
      optional :s3_region, type: String
      optional :server_certificate, type: String
      optional :server_host_key, type: String
      optional :server_type, type: String
      optional :ssl, type: String
      optional :username, type: String
      optional :google_cloud_storage_bucket, type: String
      optional :google_cloud_storage_project_id, type: String
      optional :backblaze_b2_bucket, type: String
      optional :backblaze_b2_s3_endpoint, type: String
      optional :wasabi_bucket, type: String
      optional :wasabi_region, type: String
      optional :rackspace_username, type: String
      optional :rackspace_region, type: String
      optional :rackspace_container, type: String
      optional :one_drive_account_type, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_blob_storage_container, type: String
      optional :azure_blob_storage_hierarchical_namespace, type: Boolean
      optional :azure_blob_storage_sas_token, type: String
      optional :azure_files_storage_account, type: String
      optional :azure_files_storage_share_name, type: String
      optional :azure_files_storage_sas_token, type: String
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_endpoint, type: String
      optional :s3_compatible_region, type: String
      optional :enable_dedicated_ips, type: Boolean
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_secret_key, type: String
      optional :files_agent_root, type: String
      optional :files_agent_permission_set, type: String
      optional :files_agent_version, type: String
      optional :filebase_access_key, type: String
      optional :filebase_secret_key, type: String
      optional :filebase_bucket, type: String
      optional :cloudflare_access_key, type: String
      optional :cloudflare_secret_key, type: String
      optional :cloudflare_bucket, type: String
      optional :cloudflare_endpoint, type: String
      optional :dropbox_teams, type: Boolean
      optional :linode_access_key, type: String
      optional :linode_secret_key, type: String
      optional :linode_bucket, type: String
      optional :linode_region, type: String
    end
    patch "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "disabled" => true, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "pin_to_site_region" => true, "pinned_region" => "us-east-1", "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "aws_access_key" => "example", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "wasabi_access_key" => "example", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "azure_blob_storage_hierarchical_namespace" => true, "azure_files_storage_account" => "storage-account-name", "azure_files_storage_share_name" => "share-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_endpoint" => "mys3platform.com", "s3_compatible_region" => "us-east-1", "s3_compatible_access_key" => "example", "enable_dedicated_ips" => true, "files_agent_permission_set" => "read_write", "files_agent_root" => "example", "files_agent_api_token" => "example", "files_agent_version" => "example", "filebase_bucket" => "my-bucket", "filebase_access_key" => "example", "cloudflare_bucket" => "my-bucket", "cloudflare_access_key" => "example", "cloudflare_endpoint" => "https://<ACCOUNT_ID>.r2.cloudflarestorage.com", "dropbox_teams" => true, "linode_bucket" => "my-bucket", "linode_access_key" => "example", "linode_region" => "us-east-1", "supports_versioning" => true }
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
