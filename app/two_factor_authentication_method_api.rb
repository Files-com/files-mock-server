module FilesMockServer
  class TwoFactorAuthenticationMethodAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/2fa" do
      status 200
      [ { "id" => 1, "name" => "My Verizon Phone", "method_type" => "sms", "phone_number" => "+15555555555", "phone_number_country" => "US", "phone_number_national_format" => "+15555555555", "secret_tokens" => [ "example" ], "setup_expired" => true, "setup_complete" => true, "setup_expires_at" => "2000-01-01T01:00:00Z", "totp_provisioning_uri" => "https://...", "webauthn_registration_options" => { "key" => "example value" }, "bypass_for_ftp_sftp_dav" => true } ]
    end

    params do
      requires :method_type, type: String
      optional :name, type: String
      optional :phone_number, type: String
      optional :bypass_for_ftp_sftp_dav, type: Boolean
    end
    post "/api/rest/v1/2fa" do
      status 201
      { "id" => 1, "name" => "My Verizon Phone", "method_type" => "sms", "phone_number" => "+15555555555", "phone_number_country" => "US", "phone_number_national_format" => "+15555555555", "secret_tokens" => [ "example" ], "setup_expired" => true, "setup_complete" => true, "setup_expires_at" => "2000-01-01T01:00:00Z", "totp_provisioning_uri" => "https://...", "webauthn_registration_options" => { "key" => "example value" }, "bypass_for_ftp_sftp_dav" => true }
    end

    params do
      optional :webauthn_only, type: Boolean
    end
    post "/api/rest/v1/2fa/send_code" do
      status 200
      { "webauthn_authentication_options" => [ "example" ] }
    end

    post "/api/rest/v1/2fa/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :otp, type: String
      optional :name, type: String
      optional :bypass_for_ftp_sftp_dav, type: Boolean
    end
    patch "/api/rest/v1/2fa/:id" do
      status 200
      { "id" => 1, "name" => "My Verizon Phone", "method_type" => "sms", "phone_number" => "+15555555555", "phone_number_country" => "US", "phone_number_national_format" => "+15555555555", "secret_tokens" => [ "example" ], "setup_expired" => true, "setup_complete" => true, "setup_expires_at" => "2000-01-01T01:00:00Z", "totp_provisioning_uri" => "https://...", "webauthn_registration_options" => { "key" => "example value" }, "bypass_for_ftp_sftp_dav" => true }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/2fa/:id" do
      status 204
      body false
    end
  end
end
