module FilesMockServer
  class RemoteServerAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/remote_servers" do
      status 200
      [{"id"=>1, "authentication_method"=>"password", "hostname"=>"remote-server.com", "name"=>"My Remote server", "port"=>1, "max_connections"=>1, "s3_bucket"=>"my-bucket", "s3_region"=>"us-east-1", "server_certificate"=>"[certificate]", "server_host_key"=>"[public key]", "server_type"=>"s3", "ssl"=>"always", "username"=>"user", "google_cloud_storage_bucket"=>"my-bucket", "google_cloud_storage_project_id"=>"my-project", "backblaze_b2_s3_endpoint"=>"s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket"=>"my-bucket", "wasabi_bucket"=>"us-west-1", "wasabi_region"=>"my-bucket", "rackspace_username"=>"rackspaceuser", "rackspace_region"=>"dfw", "rackspace_container"=>"my-container", "auth_setup_link"=>"auth/:provider", "auth_status"=>"in_setup", "auth_account_name"=>"me@example.com", "one_drive_account_type"=>"personnel"}]
    end

    params do
      requires :id, type: Integer
    end
    get "/remote_servers/:id" do
      status 200
      {"id"=>1, "authentication_method"=>"password", "hostname"=>"remote-server.com", "name"=>"My Remote server", "port"=>1, "max_connections"=>1, "s3_bucket"=>"my-bucket", "s3_region"=>"us-east-1", "server_certificate"=>"[certificate]", "server_host_key"=>"[public key]", "server_type"=>"s3", "ssl"=>"always", "username"=>"user", "google_cloud_storage_bucket"=>"my-bucket", "google_cloud_storage_project_id"=>"my-project", "backblaze_b2_s3_endpoint"=>"s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket"=>"my-bucket", "wasabi_bucket"=>"us-west-1", "wasabi_region"=>"my-bucket", "rackspace_username"=>"rackspaceuser", "rackspace_region"=>"dfw", "rackspace_container"=>"my-container", "auth_setup_link"=>"auth/:provider", "auth_status"=>"in_setup", "auth_account_name"=>"me@example.com", "one_drive_account_type"=>"personnel"}
    end

    params do
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
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
    end
    post "/remote_servers" do
      status 201
      {"id"=>1, "authentication_method"=>"password", "hostname"=>"remote-server.com", "name"=>"My Remote server", "port"=>1, "max_connections"=>1, "s3_bucket"=>"my-bucket", "s3_region"=>"us-east-1", "server_certificate"=>"[certificate]", "server_host_key"=>"[public key]", "server_type"=>"s3", "ssl"=>"always", "username"=>"user", "google_cloud_storage_bucket"=>"my-bucket", "google_cloud_storage_project_id"=>"my-project", "backblaze_b2_s3_endpoint"=>"s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket"=>"my-bucket", "wasabi_bucket"=>"us-west-1", "wasabi_region"=>"my-bucket", "rackspace_username"=>"rackspaceuser", "rackspace_region"=>"dfw", "rackspace_container"=>"my-container", "auth_setup_link"=>"auth/:provider", "auth_status"=>"in_setup", "auth_account_name"=>"me@example.com", "one_drive_account_type"=>"personnel"}
    end

    params do
      requires :id, type: Integer
      optional :aws_access_key, type: String
      optional :aws_secret_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :google_cloud_storage_credentials_json, type: String
      optional :wasabi_access_key, type: String
      optional :wasabi_secret_key, type: String
      optional :backblaze_b2_key_id, type: String
      optional :backblaze_b2_application_key, type: String
      optional :rackspace_api_key, type: String
      optional :reset_authentication, type: Boolean
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
    end
    patch "/remote_servers/:id" do
      status 200
      {"id"=>1, "authentication_method"=>"password", "hostname"=>"remote-server.com", "name"=>"My Remote server", "port"=>1, "max_connections"=>1, "s3_bucket"=>"my-bucket", "s3_region"=>"us-east-1", "server_certificate"=>"[certificate]", "server_host_key"=>"[public key]", "server_type"=>"s3", "ssl"=>"always", "username"=>"user", "google_cloud_storage_bucket"=>"my-bucket", "google_cloud_storage_project_id"=>"my-project", "backblaze_b2_s3_endpoint"=>"s3.us-west-001.backblazeb2.com", "backblaze_b2_bucket"=>"my-bucket", "wasabi_bucket"=>"us-west-1", "wasabi_region"=>"my-bucket", "rackspace_username"=>"rackspaceuser", "rackspace_region"=>"dfw", "rackspace_container"=>"my-container", "auth_setup_link"=>"auth/:provider", "auth_status"=>"in_setup", "auth_account_name"=>"me@example.com", "one_drive_account_type"=>"personnel"}
    end

    params do
      requires :id, type: Integer
    end
    delete "/remote_servers/:id" do
      status 204
      body false
    end
  end
end
