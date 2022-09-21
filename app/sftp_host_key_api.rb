module FilesMockServer
  class SftpHostKeyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys" do
      status 200
      [ { "id" => 1, "name" => "", "fingerprint_md5" => "", "fingerprint_sha256" => "" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "", "fingerprint_md5" => "", "fingerprint_sha256" => "" }
    end

    params do
      optional :name, type: String
      optional :private_key, type: String
    end
    post "/api/rest/v1/sftp_host_keys" do
      status 201
      { "id" => 1, "name" => "", "fingerprint_md5" => "", "fingerprint_sha256" => "" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :private_key, type: String
    end
    patch "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "", "fingerprint_md5" => "", "fingerprint_sha256" => "" }
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
