module FilesMockServer
  class RemoteServerAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/remote_servers" do
      status 200
      [ { "id" => 1, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_region" => "us-east-1", "s3_compatible_endpoint" => "mys3platform.com", "enable_dedicated_ips" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_region" => "us-east-1", "s3_compatible_endpoint" => "mys3platform.com", "enable_dedicated_ips" => true }
    end

    params do
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :ssl_certificate, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
      optional :azure_blob_storage_access_key, type: String
      optional :hostname, type: String
      optional :name, type: String
      optional :max_connections, type: Integer
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
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_region, type: String
      optional :s3_compatible_endpoint, type: String
      optional :enable_dedicated_ips, type: Boolean
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_secret_key, type: String
    end
    post "/api/rest/v1/remote_servers" do
      status 201
      { "id" => 1, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_region" => "us-east-1", "s3_compatible_endpoint" => "mys3platform.com", "enable_dedicated_ips" => true }
    end

    params do
      requires :id, type: Integer
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :ssl_certificate, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
      optional :azure_blob_storage_access_key, type: String
      optional :hostname, type: String
      optional :name, type: String
      optional :max_connections, type: Integer
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
      optional :s3_compatible_bucket, type: String
      optional :s3_compatible_region, type: String
      optional :s3_compatible_endpoint, type: String
      optional :enable_dedicated_ips, type: Boolean
      optional :s3_compatible_access_key, type: String
      optional :s3_compatible_secret_key, type: String
    end
    patch "/api/rest/v1/remote_servers/:id" do
      status 200
      { "id" => 1, "authentication_method" => "password", "hostname" => "remote-server.com", "remote_home_path" => "/home/user1", "name" => "My Remote server", "port" => 1, "max_connections" => 1, "s3_bucket" => "my-bucket", "s3_region" => "us-east-1", "server_certificate" => "require_match", "server_host_key" => "[public key]", "server_type" => "s3", "ssl" => "if_available", "username" => "user", "google_cloud_storage_bucket" => "my-bucket", "google_cloud_storage_project_id" => "my-project", "backblaze_b2_s3_endpoint" => "s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket" => "my-bucket", "wasabi_bucket" => "my-bucket", "wasabi_region" => "us-west-1", "rackspace_username" => "rackspaceuser", "rackspace_region" => "dfw", "rackspace_container" => "my-container", "auth_setup_link" => "auth/:provider", "auth_status" => "in_setup", "auth_account_name" => "me@example.com", "one_drive_account_type" => "personal", "azure_blob_storage_account" => "storage-account-name", "azure_blob_storage_container" => "container-name", "s3_compatible_bucket" => "my-bucket", "s3_compatible_region" => "us-east-1", "s3_compatible_endpoint" => "mys3platform.com", "enable_dedicated_ips" => true }
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
