module FilesMockServer
  class SessionAPI < Grape::API
    format :json

    params do
      optional :username, type: String
      optional :password, type: String
      optional :aws_access_key_id, type: String
      optional :change_password, type: String
      optional :change_password_confirmation, type: String
      optional :interface, type: String
      optional :ssh_client_identification, type: String
      optional :locale, type: String
      optional :no_cookie, type: Boolean
      optional :oauth_provider, type: String
      optional :oauth_label, type: String
      optional :oauth_code, type: String
      optional :oauth_state, type: String
      optional :otp, type: String
      optional :partial_session_id, type: String
    end
    post "/api/rest/v1/sessions" do
      status 201
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "aws_secret_key" => "example", "ai_assistant_personality_id" => 1, "ai_assistant_personality_system_prompt" => "example", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "default_workspace_id" => 1, "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => true, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "trusted" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "finalize_partial_uploads" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true, "user_belongs_to_parent_site" => true, "impersonator_user_id" => 1 }
    end

    params do
      requires :subdomain, type: String
    end
    post "/api/rest/v1/sessions/subdomain" do
      status 201
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "aws_secret_key" => "example", "ai_assistant_personality_id" => 1, "ai_assistant_personality_system_prompt" => "example", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "default_workspace_id" => 1, "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => true, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "trusted" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "finalize_partial_uploads" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true, "user_belongs_to_parent_site" => true, "impersonator_user_id" => 1 }
    end

    params do
      requires :user_id, type: String
    end
    post "/api/rest/v1/sessions/as_user" do
      status 201
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "aws_secret_key" => "example", "ai_assistant_personality_id" => 1, "ai_assistant_personality_system_prompt" => "example", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "default_workspace_id" => 1, "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => true, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "trusted" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "finalize_partial_uploads" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true, "user_belongs_to_parent_site" => true, "impersonator_user_id" => 1 }
    end

    params do
      requires :session_id, type: String
    end
    post "/api/rest/v1/sessions/trusted" do
      status 201
      { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "aws_secret_key" => "example", "ai_assistant_personality_id" => 1, "ai_assistant_personality_system_prompt" => "example", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "default_workspace_id" => 1, "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => true, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "trusted" => true, "two_factor_setup_needed" => true, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "finalize_partial_uploads" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => true, "user_belongs_to_parent_site" => true, "impersonator_user_id" => 1 }
    end

    params do
      requires :code, type: String
      requires :password, type: String
      optional :confirm_password, type: String
      optional :interface, type: String
      optional :locale, type: String
      optional :otp, type: String
    end
    post "/api/rest/v1/sessions/forgot/reset" do
      status 201
      body false
    end

    params do
      requires :code, type: String
    end
    post "/api/rest/v1/sessions/forgot/validate" do
      status 200
      body false
    end

    params do
      optional :email, type: String
      optional :username, type: String
      optional :username_or_email, type: String
    end
    post "/api/rest/v1/sessions/forgot" do
      status 200
      body false
    end

    params do
      requires :return_to, type: String
    end
    post "/api/rest/v1/sessions/public_hosting" do
      status 201
      { "pairing_key" => "example", "redirect_uri" => "example", "expires_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :key, type: String
    end
    post "/api/rest/v1/sessions/pairing_key/:key" do
      status 201
      { "server" => "mysite.files.com", "username" => "@api-1", "password" => "", "user_username" => "my_user", "nickname" => "my_user @ mysite.files.com" }
    end

    params do
      requires :provider, type: String
      optional :label, type: String
      optional :state, type: String
      optional :host, type: String
    end
    post "/api/rest/v1/sessions/oauth" do
      status 201
      { "redirect_uri" => "https://provider.com/redirect..." }
    end

    delete "/api/rest/v1/sessions" do
      status 204
      body false
    end
  end
end
