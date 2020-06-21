module FilesMockServer
  class SessionAPI < Grape::API
    format :json

    params do
      optional :username, type: String
      optional :password, type: String
      optional :otp, type: String
      optional :partial_session_id, type: String
    end
    post "/sessions" do
      status 201
      { "id" => 1, "language" => "en", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => "en", "root_path" => "", "site_id" => 1, "ssl_required" => true, "tls_disabled" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_u2f" => true, "allowed_2fa_method_yubi" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true }
    end

    delete "/sessions" do
      status 204
      body false
    end
  end
end
