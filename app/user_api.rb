module FilesMockServer
  class UserAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :ids, type: String
      optional :include_parent_site_users, type: Boolean
      optional :search, type: String
    end
    get "/api/rest/v1/users" do
      status 200
      [ { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_user_lifecycle_rules" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "filesystem_layout" => "site_root", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "partner_admin" => true, "partner_id" => 1, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/users/:id" do
      status 200
      { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_user_lifecycle_rules" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "filesystem_layout" => "site_root", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "partner_admin" => true, "partner_id" => 1, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :avatar_file, type: File
      optional :avatar_delete, type: Boolean
      optional :change_password, type: String
      optional :change_password_confirmation, type: String
      optional :email, type: String
      optional :grant_permission, type: String
      optional :group_id, type: Integer
      optional :group_ids, type: String
      optional :imported_password_hash, type: String
      optional :password, type: String
      optional :password_confirmation, type: String
      optional :announcements_read, type: Boolean
      optional :allowed_ips, type: String
      optional :attachments_permission, type: Boolean
      optional :authenticate_until, type: String
      optional :authentication_method, type: String
      optional :billing_permission, type: Boolean
      optional :bypass_user_lifecycle_rules, type: Boolean
      optional :bypass_site_allowed_ips, type: Boolean
      optional :dav_permission, type: Boolean
      optional :disabled, type: Boolean
      optional :filesystem_layout, type: String
      optional :ftp_permission, type: Boolean
      optional :header_text, type: String
      optional :language, type: String
      optional :notification_daily_send_time, type: Integer
      optional :name, type: String
      optional :company, type: String
      optional :notes, type: String
      optional :office_integration_enabled, type: Boolean
      optional :partner_admin, type: Boolean
      optional :partner_id, type: Integer
      optional :password_validity_days, type: Integer
      optional :readonly_site_admin, type: Boolean
      optional :receive_admin_alerts, type: Boolean
      optional :require_login_by, type: String
      optional :require_password_change, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :self_managed, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :site_admin, type: Boolean
      optional :skip_welcome_screen, type: Boolean
      optional :ssl_required, type: String
      optional :sso_strategy_id, type: Integer
      optional :subscribe_to_newsletter, type: Boolean
      optional :require_2fa, type: String
      optional :time_zone, type: String
      optional :user_root, type: String
      optional :user_home, type: String
      requires :username, type: String
    end
    post "/api/rest/v1/users" do
      status 201
      { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_user_lifecycle_rules" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "filesystem_layout" => "site_root", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "partner_admin" => true, "partner_id" => 1, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/users/:id/unlock" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/users/:id/resend_welcome_email" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/users/:id/2fa/reset" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :avatar_file, type: File
      optional :avatar_delete, type: Boolean
      optional :change_password, type: String
      optional :change_password_confirmation, type: String
      optional :email, type: String
      optional :grant_permission, type: String
      optional :group_id, type: Integer
      optional :group_ids, type: String
      optional :imported_password_hash, type: String
      optional :password, type: String
      optional :password_confirmation, type: String
      optional :announcements_read, type: Boolean
      optional :allowed_ips, type: String
      optional :attachments_permission, type: Boolean
      optional :authenticate_until, type: String
      optional :authentication_method, type: String
      optional :billing_permission, type: Boolean
      optional :bypass_user_lifecycle_rules, type: Boolean
      optional :bypass_site_allowed_ips, type: Boolean
      optional :dav_permission, type: Boolean
      optional :disabled, type: Boolean
      optional :filesystem_layout, type: String
      optional :ftp_permission, type: Boolean
      optional :header_text, type: String
      optional :language, type: String
      optional :notification_daily_send_time, type: Integer
      optional :name, type: String
      optional :company, type: String
      optional :notes, type: String
      optional :office_integration_enabled, type: Boolean
      optional :partner_admin, type: Boolean
      optional :partner_id, type: Integer
      optional :password_validity_days, type: Integer
      optional :readonly_site_admin, type: Boolean
      optional :receive_admin_alerts, type: Boolean
      optional :require_login_by, type: String
      optional :require_password_change, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :self_managed, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :site_admin, type: Boolean
      optional :skip_welcome_screen, type: Boolean
      optional :ssl_required, type: String
      optional :sso_strategy_id, type: Integer
      optional :subscribe_to_newsletter, type: Boolean
      optional :require_2fa, type: String
      optional :time_zone, type: String
      optional :user_root, type: String
      optional :user_home, type: String
      optional :username, type: String
      optional :clear_2fa, type: Boolean
    end
    patch "/api/rest/v1/users/:id" do
      status 200
      { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_user_lifecycle_rules" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "filesystem_layout" => "site_root", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "partner_admin" => true, "partner_id" => 1, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :new_owner_id, type: Integer
    end
    delete "/api/rest/v1/users/:id" do
      status 204
      body false
    end
  end
end
