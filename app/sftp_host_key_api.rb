module FilesMockServer
  class SftpHostKeyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys" do
      status 200
      [ { "id" => 1, "name" => "My Key", "fingerprint_md5" => "12:7e:f8:61:78:a4:b2:c2:ee:12:51:92:25:a7:42:cc", "fingerprint_sha256" => "SHA256:5ANRkDpXWA+PgOquzZAG9RtQ1Bt8KXYAH2hecr7LQk8" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "My Key", "fingerprint_md5" => "12:7e:f8:61:78:a4:b2:c2:ee:12:51:92:25:a7:42:cc", "fingerprint_sha256" => "SHA256:5ANRkDpXWA+PgOquzZAG9RtQ1Bt8KXYAH2hecr7LQk8" }
    end

    params do
      optional :name, type: String
      optional :private_key, type: String
    end
    post "/api/rest/v1/sftp_host_keys" do
      status 201
      { "id" => 1, "name" => "My Key", "fingerprint_md5" => "12:7e:f8:61:78:a4:b2:c2:ee:12:51:92:25:a7:42:cc", "fingerprint_sha256" => "SHA256:5ANRkDpXWA+PgOquzZAG9RtQ1Bt8KXYAH2hecr7LQk8" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :private_key, type: String
    end
    patch "/api/rest/v1/sftp_host_keys/:id" do
      status 200
      { "id" => 1, "name" => "My Key", "fingerprint_md5" => "12:7e:f8:61:78:a4:b2:c2:ee:12:51:92:25:a7:42:cc", "fingerprint_sha256" => "SHA256:5ANRkDpXWA+PgOquzZAG9RtQ1Bt8KXYAH2hecr7LQk8" }
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
