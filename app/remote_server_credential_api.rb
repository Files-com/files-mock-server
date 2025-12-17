module FilesMockServer
  class RemoteServerCredentialAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/remote_server_credentials" do
      status 200
      [ { "id" => 1, "name" => "My Credential", "description" => "More information or notes about this credential.", "server_type" => "s3", "aws_access_key" => "example", "google_cloud_storage_s3_compatible_access_key" => "example", "wasabi_access_key" => "example", "azure_blob_storage_account" => "storage-account-name", "azure_files_storage_account" => "storage-account-name", "s3_compatible_access_key" => "example", "filebase_access_key" => "example", "cloudflare_access_key" => "example", "linode_access_key" => "example", "username" => "user" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_server_credentials/:id" do
      status 200
      { "id" => 1, "name" => "My Credential", "description" => "More information or notes about this credential.", "server_type" => "s3", "aws_access_key" => "example", "google_cloud_storage_s3_compatible_access_key" => "example", "wasabi_access_key" => "example", "azure_blob_storage_account" => "storage-account-name", "azure_files_storage_account" => "storage-account-name", "s3_compatible_access_key" => "example", "filebase_access_key" => "example", "cloudflare_access_key" => "example", "linode_access_key" => "example", "username" => "user" }
    end

    params do
      optional :name, type: String
      optional :description, type: String
      optional :server_type, type: String
      optional :aws_access_key, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_files_storage_account, type: String
      optional :cloudflare_access_key, type: String
      optional :filebase_access_key, type: String
      optional :google_cloud_storage_s3_compatible_access_key, type: String
      optional :linode_access_key, type: String
      optional :s3_compatible_access_key, type: String
      optional :username, type: String
      optional :wasabi_access_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
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
    end
    post "/api/rest/v1/remote_server_credentials" do
      status 201
      { "id" => 1, "name" => "My Credential", "description" => "More information or notes about this credential.", "server_type" => "s3", "aws_access_key" => "example", "google_cloud_storage_s3_compatible_access_key" => "example", "wasabi_access_key" => "example", "azure_blob_storage_account" => "storage-account-name", "azure_files_storage_account" => "storage-account-name", "s3_compatible_access_key" => "example", "filebase_access_key" => "example", "cloudflare_access_key" => "example", "linode_access_key" => "example", "username" => "user" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :description, type: String
      optional :server_type, type: String
      optional :aws_access_key, type: String
      optional :azure_blob_storage_account, type: String
      optional :azure_files_storage_account, type: String
      optional :cloudflare_access_key, type: String
      optional :filebase_access_key, type: String
      optional :google_cloud_storage_s3_compatible_access_key, type: String
      optional :linode_access_key, type: String
      optional :s3_compatible_access_key, type: String
      optional :username, type: String
      optional :wasabi_access_key, type: String
      optional :password, type: String
      optional :private_key, type: String
      optional :private_key_passphrase, type: String
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
    end
    patch "/api/rest/v1/remote_server_credentials/:id" do
      status 200
      { "id" => 1, "name" => "My Credential", "description" => "More information or notes about this credential.", "server_type" => "s3", "aws_access_key" => "example", "google_cloud_storage_s3_compatible_access_key" => "example", "wasabi_access_key" => "example", "azure_blob_storage_account" => "storage-account-name", "azure_files_storage_account" => "storage-account-name", "s3_compatible_access_key" => "example", "filebase_access_key" => "example", "cloudflare_access_key" => "example", "linode_access_key" => "example", "username" => "user" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/remote_server_credentials/:id" do
      status 204
      body false
    end
  end
end
