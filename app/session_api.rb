module FilesMockServer
  class SessionAPI < Grape::API
    format :json

    params do
      optional :username, type: String
      optional :password, type: String
      optional :otp, type: String
      optional :partial_session_id, type: String
    end
    post "/api/rest/v1/sessions" do
      status 201
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "read_only" => true, "sftp_insecure_ciphers" => true }
    end

    delete "/api/rest/v1/sessions" do
      status 204
      body false
    end
  end
end
