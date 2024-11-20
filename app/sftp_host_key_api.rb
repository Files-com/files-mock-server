module FilesMockServer
  class SftpHostKeyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys" do
      status 200
      [ { "id" => 1, "name" => "example", "fingerprint_md5" => "example", "fingerprint_sha256" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "example", "fingerprint_md5" => "example", "fingerprint_sha256" => "example" }
    end

    params do
      optional :name, type: String
      optional :private_key, type: String
    end
    post "/api/rest/v1/sftp_host_keys" do
      status 201
      { "id" => 1, "name" => "example", "fingerprint_md5" => "example", "fingerprint_sha256" => "example" }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    post "/api/rest/v1/sftp_host_keys/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :private_key, type: String
    end
    patch "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "example", "fingerprint_md5" => "example", "fingerprint_sha256" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/sftp_host_keys/:id" do
      status 204
      body false
    end
  end
end
