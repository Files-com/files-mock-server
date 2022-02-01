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
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "", "sftp_insecure_ciphers" => true, "site_id" => 1, "ssl_required" => true, "tls_disabled" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_u2f" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true }
    end

    delete "/api/rest/v1/sessions" do
      status 204
      body false
    end
  end
end
