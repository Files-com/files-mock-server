module FilesMockServer
  class UserAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional "q[username]", type: String
      optional "q[email]", type: String
      optional "q[notes]", type: String
      optional "q[admin]", type: String
      optional "q[allowed_ips]", type: String
      optional "q[password_validity_days]", type: String
      optional "q[ssl_required]", type: String
      optional :search, type: String
      optional "sort_by[last_login_at]", type: String
      optional "sort_by[authenticate_until]", type: String
    end
    get "/users" do
      status 200
      [ { "id" => 1, "username" => "user", "admin_group_ids" => [], "allowed_ips" => "127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "", "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_inactive_disable" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "email" => "john.doe@files.com", "ftp_permission" => true, "group_ids" => [], "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => true, "require_password_change" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "", "user_root" => "" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/users/:id" do
      status 200
      { "id" => 1, "username" => "user", "admin_group_ids" => [], "allowed_ips" => "127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "", "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_inactive_disable" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "email" => "john.doe@files.com", "ftp_permission" => true, "group_ids" => [], "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => true, "require_password_change" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "", "user_root" => "" }
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
      optional :password, type: String
      optional :password_confirmation, type: String
      optional :announcements_read, type: Boolean
      optional :allowed_ips, type: String
      optional :attachments_permission, type: Boolean
      optional :authenticate_until, type: String
      optional :authentication_method, type: String
      optional :billing_permission, type: Boolean
      optional :bypass_inactive_disable, type: Boolean
      optional :bypass_site_allowed_ips, type: Boolean
      optional :dav_permission, type: Boolean
      optional :disabled, type: Boolean
      optional :ftp_permission, type: Boolean
      optional :header_text, type: String
      optional :language, type: String
      optional :notification_daily_send_time, type: Integer
      optional :name, type: String
      optional :notes, type: String
      optional :password_validity_days, type: Integer
      optional :receive_admin_alerts, type: Boolean
      optional :require_password_change, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :self_managed, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :site_admin, type: Boolean
      optional :skip_welcome_screen, type: Boolean
      optional :ssl_required, type: String
      optional :sso_strategy_id, type: Integer
      optional :subscribe_to_newsletter, type: Boolean
      optional :time_zone, type: String
      optional :user_root, type: String
      optional :username, type: String
    end
    post "/users" do
      status 201
      { "id" => 1, "username" => "user", "admin_group_ids" => [], "allowed_ips" => "127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "", "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_inactive_disable" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "email" => "john.doe@files.com", "ftp_permission" => true, "group_ids" => [], "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => true, "require_password_change" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "", "user_root" => "" }
    end

    params do
      requires :id, type: Integer
    end
    post "/users/:id/unlock" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/users/:id/resend_welcome_email" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/users/:id/2fa/reset" do
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
      optional :password, type: String
      optional :password_confirmation, type: String
      optional :announcements_read, type: Boolean
      optional :allowed_ips, type: String
      optional :attachments_permission, type: Boolean
      optional :authenticate_until, type: String
      optional :authentication_method, type: String
      optional :billing_permission, type: Boolean
      optional :bypass_inactive_disable, type: Boolean
      optional :bypass_site_allowed_ips, type: Boolean
      optional :dav_permission, type: Boolean
      optional :disabled, type: Boolean
      optional :ftp_permission, type: Boolean
      optional :header_text, type: String
      optional :language, type: String
      optional :notification_daily_send_time, type: Integer
      optional :name, type: String
      optional :notes, type: String
      optional :password_validity_days, type: Integer
      optional :receive_admin_alerts, type: Boolean
      optional :require_password_change, type: Boolean
      optional :restapi_permission, type: Boolean
      optional :self_managed, type: Boolean
      optional :sftp_permission, type: Boolean
      optional :site_admin, type: Boolean
      optional :skip_welcome_screen, type: Boolean
      optional :ssl_required, type: String
      optional :sso_strategy_id, type: Integer
      optional :subscribe_to_newsletter, type: Boolean
      optional :time_zone, type: String
      optional :user_root, type: String
      optional :username, type: String
    end
    patch "/users/:id" do
      status 200
      { "id" => 1, "username" => "user", "admin_group_ids" => [], "allowed_ips" => "127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "", "billing_permission" => true, "bypass_site_allowed_ips" => true, "bypass_inactive_disable" => true, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "email" => "john.doe@files.com", "ftp_permission" => true, "group_ids" => [], "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => true, "require_password_change" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "", "user_root" => "" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/users/:id" do
      status 204
      body false
    end
  end
end
