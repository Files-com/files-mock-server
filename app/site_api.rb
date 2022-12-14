module FilesMockServer
  class SiteAPI < Grape::API
    format :json

    get "/api/rest/v1/site" do
      status 200
      { "name" => "My Site", "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_u2f" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "allowed_2fa_method_bypass_for_ftp_sftp_dav" => true, "admin_user_id" => 1, "allow_bundle_names" => true, "allowed_countries" => "US,DE", "allowed_ips" => "example", "ask_about_overwrites" => true, "bundle_activity_notifications" => "never", "bundle_expiration" => 1, "bundle_password_required" => true, "bundle_registration_notifications" => "never", "bundle_require_share_recipient" => true, "bundle_upload_receipt_notifications" => "never", "bundle_watermark_attachment" => "", "bundle_watermark_value" => { "key" => "example value" }, "color2_left" => "#0066a7", "color2_link" => "#d34f5d", "color2_text" => "#0066a7", "color2_top" => "#000000", "color2_top_text" => "#ffffff", "contact_name" => "John Doe", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "custom_namespace" => true, "days_to_retain_backups" => 30, "default_time_zone" => "Pacific Time (US & Canada)", "desktop_app" => true, "desktop_app_session_ip_pinning" => true, "desktop_app_session_lifetime" => 1, "mobile_app" => true, "mobile_app_session_ip_pinning" => true, "mobile_app_session_lifetime" => 1, "disallowed_countries" => "US,DE", "disable_files_certificate_generation" => true, "disable_notifications" => true, "disable_password_reset" => true, "domain" => "my-custom-domain.com", "domain_hsts_header" => true, "domain_letsencrypt_chain" => "example", "email" => "example", "ftp_enabled" => true, "reply_to_email" => "example", "non_sso_groups_allowed" => true, "non_sso_users_allowed" => true, "folder_permissions_groups_only" => true, "hipaa" => true, "icon128" => "", "icon16" => "", "icon32" => "", "icon48" => "", "immutable_files_set_at" => "2000-01-01T01:00:00Z", "include_password_in_welcome_email" => true, "language" => "en", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "ldap_enabled" => true, "ldap_group_action" => "disabled", "ldap_group_exclusion" => "example", "ldap_group_inclusion" => "example", "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_type" => "open_ldap", "ldap_user_action" => "disabled", "ldap_user_include_groups" => "example", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName", "login_help_text" => "Login page help text.", "logo" => "", "max_prior_passwords" => 1, "motd_text" => "example", "motd_use_for_ftp" => true, "motd_use_for_sftp" => true, "next_billing_amount" => 1.0, "next_billing_date" => "Apr 20", "office_integration_available" => true, "oncehub_link" => "https://go.oncehub.com/files", "opt_out_global" => true, "overage_notified_at" => "2000-01-01T01:00:00Z", "overage_notify" => true, "overdue" => true, "password_min_length" => 1, "password_require_letter" => true, "password_require_mixed" => true, "password_require_number" => true, "password_require_special" => true, "password_require_unbreached" => true, "password_requirements_apply_to_bundles" => true, "password_validity_days" => 1, "phone" => "555-555-5555", "pin_all_remote_servers_to_site_region" => true, "require_2fa" => true, "require_2fa_stop_time" => "2000-01-01T01:00:00Z", "require_2fa_user_type" => "`site_admins`", "session" => "", "session_pinned_by_ip" => true, "sftp_enabled" => true, "sftp_host_key_type" => "default", "active_sftp_host_key_id" => 1, "sftp_insecure_ciphers" => true, "sftp_user_root_enabled" => true, "sharing_enabled" => true, "show_request_access_link" => true, "site_footer" => "example", "site_header" => "example", "smtp_address" => "smtp.my-mail-server.com", "smtp_authentication" => "plain", "smtp_from" => "me@my-mail-server.com", "smtp_port" => 25, "smtp_username" => "mail", "session_expiry" => 6.0, "ssl_required" => true, "subdomain" => "mysite", "switch_to_plan_date" => "2000-01-01T01:00:00Z", "tls_disabled" => true, "trial_days_left" => 1, "trial_until" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "use_provided_modified_at" => true, "user" => "", "user_lockout" => true, "user_lockout_lock_period" => 1, "user_lockout_tries" => 1, "user_lockout_within" => 6, "user_requests_enabled" => true, "user_requests_notify_admins" => true, "welcome_custom_text" => "Welcome to my site!", "welcome_email_cc" => "example", "welcome_email_subject" => "example", "welcome_email_enabled" => true, "welcome_screen" => "user_controlled", "windows_mode_ftp" => true, "disable_users_from_inactivity_period_days" => 1 }
    end

    get "/api/rest/v1/site/usage" do
      status 200
      { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "created_at" => "2000-01-01T01:00:00Z", "high_water_user_count" => 1.0, "current_storage" => 1.0, "high_water_storage" => 1.0, "total_downloads" => 1, "total_uploads" => 1, "updated_at" => "2000-01-01T01:00:00Z", "usage_by_top_level_dir" => { "key" => "example value" }, "root_storage" => 1.0, "deleted_files_counted_in_minimum" => 1.0, "deleted_files_storage" => 1.0, "total_billable_usage" => 1.0, "total_billable_transfer_usage" => 1.0, "bytes_sent" => 1.0, "sync_bytes_received" => 1.0, "sync_bytes_sent" => 1.0 }
    end

    params do
      optional :name, type: String
      optional :subdomain, type: String
      optional :domain, type: String
      optional :domain_hsts_header, type: Boolean
      optional :domain_letsencrypt_chain, type: String
      optional :email, type: String
      optional :reply_to_email, type: String
      optional :allow_bundle_names, type: Boolean
      optional :bundle_expiration, type: Integer
      optional :overage_notify, type: Boolean
      optional :welcome_email_enabled, type: Boolean
      optional :ask_about_overwrites, type: Boolean
      optional :show_request_access_link, type: Boolean
      optional :welcome_email_cc, type: String
      optional :welcome_email_subject, type: String
      optional :welcome_custom_text, type: String
      optional :language, type: String
      optional :windows_mode_ftp, type: Boolean
      optional :default_time_zone, type: String
      optional :desktop_app, type: Boolean
      optional :desktop_app_session_ip_pinning, type: Boolean
      optional :desktop_app_session_lifetime, type: Integer
      optional :mobile_app, type: Boolean
      optional :mobile_app_session_ip_pinning, type: Boolean
      optional :mobile_app_session_lifetime, type: Integer
      optional :folder_permissions_groups_only, type: Boolean
      optional :welcome_screen, type: String
      optional :office_integration_available, type: Boolean
      optional :pin_all_remote_servers_to_site_region, type: Boolean
      optional :motd_text, type: String
      optional :motd_use_for_ftp, type: Boolean
      optional :motd_use_for_sftp, type: Boolean
      optional :session_expiry, type: Float
      optional :ssl_required, type: Boolean
      optional :tls_disabled, type: Boolean
      optional :sftp_insecure_ciphers, type: Boolean
      optional :disable_files_certificate_generation, type: Boolean
      optional :user_lockout, type: Boolean
      optional :user_lockout_tries, type: Integer
      optional :user_lockout_within, type: Integer
      optional :user_lockout_lock_period, type: Integer
      optional :include_password_in_welcome_email, type: Boolean
      optional :allowed_countries, type: String
      optional :allowed_ips, type: String
      optional :disallowed_countries, type: String
      optional :days_to_retain_backups, type: Integer
      optional :max_prior_passwords, type: Integer
      optional :password_validity_days, type: Integer
      optional :password_min_length, type: Integer
      optional :password_require_letter, type: Boolean
      optional :password_require_mixed, type: Boolean
      optional :password_require_special, type: Boolean
      optional :password_require_number, type: Boolean
      optional :password_require_unbreached, type: Boolean
      optional :sftp_user_root_enabled, type: Boolean
      optional :disable_password_reset, type: Boolean
      optional :immutable_files, type: Boolean
      optional :session_pinned_by_ip, type: Boolean
      optional :bundle_password_required, type: Boolean
      optional :bundle_require_share_recipient, type: Boolean
      optional :bundle_registration_notifications, type: String
      optional :bundle_activity_notifications, type: String
      optional :bundle_upload_receipt_notifications, type: String
      optional :password_requirements_apply_to_bundles, type: Boolean
      optional :opt_out_global, type: Boolean
      optional :use_provided_modified_at, type: Boolean
      optional :custom_namespace, type: Boolean
      optional :disable_users_from_inactivity_period_days, type: Integer
      optional :non_sso_groups_allowed, type: Boolean
      optional :non_sso_users_allowed, type: Boolean
      optional :sharing_enabled, type: Boolean
      optional :user_requests_enabled, type: Boolean
      optional :user_requests_notify_admins, type: Boolean
      optional :ftp_enabled, type: Boolean
      optional :sftp_enabled, type: Boolean
      optional :sftp_host_key_type, type: String
      optional :active_sftp_host_key_id, type: Integer
      optional :bundle_watermark_value, type: Hash
      optional :allowed_2fa_method_sms, type: Boolean
      optional :allowed_2fa_method_u2f, type: Boolean
      optional :allowed_2fa_method_totp, type: Boolean
      optional :allowed_2fa_method_webauthn, type: Boolean
      optional :allowed_2fa_method_yubi, type: Boolean
      optional :allowed_2fa_method_bypass_for_ftp_sftp_dav, type: Boolean
      optional :require_2fa, type: Boolean
      optional :require_2fa_user_type, type: String
      optional :color2_top, type: String
      optional :color2_left, type: String
      optional :color2_link, type: String
      optional :color2_text, type: String
      optional :color2_top_text, type: String
      optional :site_header, type: String
      optional :site_footer, type: String
      optional :login_help_text, type: String
      optional :smtp_address, type: String
      optional :smtp_authentication, type: String
      optional :smtp_from, type: String
      optional :smtp_username, type: String
      optional :smtp_port, type: Integer
      optional :ldap_enabled, type: Boolean
      optional :ldap_type, type: String
      optional :ldap_host, type: String
      optional :ldap_host_2, type: String
      optional :ldap_host_3, type: String
      optional :ldap_port, type: Integer
      optional :ldap_secure, type: Boolean
      optional :ldap_username, type: String
      optional :ldap_username_field, type: String
      optional :ldap_domain, type: String
      optional :ldap_user_action, type: String
      optional :ldap_group_action, type: String
      optional :ldap_user_include_groups, type: String
      optional :ldap_group_exclusion, type: String
      optional :ldap_group_inclusion, type: String
      optional :ldap_base_dn, type: String
      optional :icon16_file, type: File
      optional :icon16_delete, type: Boolean
      optional :icon32_file, type: File
      optional :icon32_delete, type: Boolean
      optional :icon48_file, type: File
      optional :icon48_delete, type: Boolean
      optional :icon128_file, type: File
      optional :icon128_delete, type: Boolean
      optional :logo_file, type: File
      optional :logo_delete, type: Boolean
      optional :bundle_watermark_attachment_file, type: File
      optional :bundle_watermark_attachment_delete, type: Boolean
      optional :disable_2fa_with_delay, type: Boolean
      optional :ldap_password_change, type: String
      optional :ldap_password_change_confirmation, type: String
      optional :smtp_password, type: String
    end
    patch "/api/rest/v1/site" do
      status 200
      { "name" => "My Site", "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_u2f" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "allowed_2fa_method_bypass_for_ftp_sftp_dav" => true, "admin_user_id" => 1, "allow_bundle_names" => true, "allowed_countries" => "US,DE", "allowed_ips" => "example", "ask_about_overwrites" => true, "bundle_activity_notifications" => "never", "bundle_expiration" => 1, "bundle_password_required" => true, "bundle_registration_notifications" => "never", "bundle_require_share_recipient" => true, "bundle_upload_receipt_notifications" => "never", "bundle_watermark_attachment" => "", "bundle_watermark_value" => { "key" => "example value" }, "color2_left" => "#0066a7", "color2_link" => "#d34f5d", "color2_text" => "#0066a7", "color2_top" => "#000000", "color2_top_text" => "#ffffff", "contact_name" => "John Doe", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "custom_namespace" => true, "days_to_retain_backups" => 30, "default_time_zone" => "Pacific Time (US & Canada)", "desktop_app" => true, "desktop_app_session_ip_pinning" => true, "desktop_app_session_lifetime" => 1, "mobile_app" => true, "mobile_app_session_ip_pinning" => true, "mobile_app_session_lifetime" => 1, "disallowed_countries" => "US,DE", "disable_files_certificate_generation" => true, "disable_notifications" => true, "disable_password_reset" => true, "domain" => "my-custom-domain.com", "domain_hsts_header" => true, "domain_letsencrypt_chain" => "example", "email" => "example", "ftp_enabled" => true, "reply_to_email" => "example", "non_sso_groups_allowed" => true, "non_sso_users_allowed" => true, "folder_permissions_groups_only" => true, "hipaa" => true, "icon128" => "", "icon16" => "", "icon32" => "", "icon48" => "", "immutable_files_set_at" => "2000-01-01T01:00:00Z", "include_password_in_welcome_email" => true, "language" => "en", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "ldap_enabled" => true, "ldap_group_action" => "disabled", "ldap_group_exclusion" => "example", "ldap_group_inclusion" => "example", "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_type" => "open_ldap", "ldap_user_action" => "disabled", "ldap_user_include_groups" => "example", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName", "login_help_text" => "Login page help text.", "logo" => "", "max_prior_passwords" => 1, "motd_text" => "example", "motd_use_for_ftp" => true, "motd_use_for_sftp" => true, "next_billing_amount" => 1.0, "next_billing_date" => "Apr 20", "office_integration_available" => true, "oncehub_link" => "https://go.oncehub.com/files", "opt_out_global" => true, "overage_notified_at" => "2000-01-01T01:00:00Z", "overage_notify" => true, "overdue" => true, "password_min_length" => 1, "password_require_letter" => true, "password_require_mixed" => true, "password_require_number" => true, "password_require_special" => true, "password_require_unbreached" => true, "password_requirements_apply_to_bundles" => true, "password_validity_days" => 1, "phone" => "555-555-5555", "pin_all_remote_servers_to_site_region" => true, "require_2fa" => true, "require_2fa_stop_time" => "2000-01-01T01:00:00Z", "require_2fa_user_type" => "`site_admins`", "session" => "", "session_pinned_by_ip" => true, "sftp_enabled" => true, "sftp_host_key_type" => "default", "active_sftp_host_key_id" => 1, "sftp_insecure_ciphers" => true, "sftp_user_root_enabled" => true, "sharing_enabled" => true, "show_request_access_link" => true, "site_footer" => "example", "site_header" => "example", "smtp_address" => "smtp.my-mail-server.com", "smtp_authentication" => "plain", "smtp_from" => "me@my-mail-server.com", "smtp_port" => 25, "smtp_username" => "mail", "session_expiry" => 6.0, "ssl_required" => true, "subdomain" => "mysite", "switch_to_plan_date" => "2000-01-01T01:00:00Z", "tls_disabled" => true, "trial_days_left" => 1, "trial_until" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "use_provided_modified_at" => true, "user" => "", "user_lockout" => true, "user_lockout_lock_period" => 1, "user_lockout_tries" => 1, "user_lockout_within" => 6, "user_requests_enabled" => true, "user_requests_notify_admins" => true, "welcome_custom_text" => "Welcome to my site!", "welcome_email_cc" => "example", "welcome_email_subject" => "example", "welcome_email_enabled" => true, "welcome_screen" => "user_controlled", "windows_mode_ftp" => true, "disable_users_from_inactivity_period_days" => 1 }
    end
  end
end
