module FilesMockServer
  class SiteAPI < Grape::API
    format :json

    get "/api/rest/v1/site" do
      status 200
      { "id" => 1, "name" => "My Site", "additional_text_file_types" => [ "example" ], "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "allowed_2fa_method_email" => true, "allowed_2fa_method_static" => true, "allowed_2fa_method_bypass_for_ftp_sftp_dav" => true, "admin_user_id" => 1, "admins_bypass_locked_subfolders" => true, "allow_bundle_names" => true, "allowed_countries" => "US,DE", "allowed_ips" => "example", "always_mkdir_parents" => true, "ask_about_overwrites" => true, "bundle_activity_notifications" => "never", "bundle_expiration" => 1, "bundle_not_found_message" => "example", "bundle_password_required" => true, "bundle_recipient_blacklist_domains" => [ "example" ], "bundle_recipient_blacklist_free_email_domains" => true, "bundle_registration_notifications" => "never", "bundle_require_registration" => true, "bundle_require_share_recipient" => true, "bundle_require_note" => true, "bundle_send_shared_receipts" => true, "bundle_upload_receipt_notifications" => "never", "bundle_watermark_attachment" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "bundle_watermark_value" => { "key" => "example value" }, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "uploads_via_email_authentication" => true, "color2_left" => "#0066a7", "color2_link" => "#d34f5d", "color2_text" => "#0066a7", "color2_top" => "#000000", "color2_top_text" => "#ffffff", "contact_name" => "John Doe", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "custom_namespace" => true, "dav_enabled" => true, "dav_user_root_enabled" => true, "days_to_retain_backups" => 30, "document_edits_in_bundle_allowed" => true, "default_time_zone" => "Pacific Time (US & Canada)", "desktop_app" => true, "desktop_app_session_ip_pinning" => true, "desktop_app_session_lifetime" => 1, "legacy_checksums_mode" => true, "migrate_remote_server_sync_to_sync" => true, "mobile_app" => true, "mobile_app_session_ip_pinning" => true, "mobile_app_session_lifetime" => 1, "disallowed_countries" => "US,DE", "disable_files_certificate_generation" => true, "disable_notifications" => true, "disable_password_reset" => true, "domain" => "my-custom-domain.com", "domain_hsts_header" => true, "domain_letsencrypt_chain" => "example", "email" => "john.doe@files.com", "ftp_enabled" => true, "reply_to_email" => "jane.doe@files.com", "non_sso_groups_allowed" => true, "non_sso_users_allowed" => true, "folder_permissions_groups_only" => true, "hipaa" => true, "icon128" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon16" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon32" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon48" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "immutable_files_set_at" => "2000-01-01T01:00:00Z", "include_password_in_welcome_email" => true, "language" => "en", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "ldap_enabled" => true, "ldap_group_action" => "disabled", "ldap_group_exclusion" => "example", "ldap_group_inclusion" => "example", "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_type" => "open_ldap", "ldap_user_action" => "disabled", "ldap_user_include_groups" => "example", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName", "login_help_text" => "Login page help text.", "logo" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "login_page_background_image" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "max_prior_passwords" => 1, "motd_text" => "example", "motd_use_for_ftp" => true, "motd_use_for_sftp" => true, "next_billing_amount" => 1.0, "next_billing_date" => "Apr 20", "office_integration_available" => true, "office_integration_type" => "example", "oncehub_link" => "https://go.oncehub.com/files", "opt_out_global" => true, "overdue" => true, "password_min_length" => 1, "password_require_letter" => true, "password_require_mixed" => true, "password_require_number" => true, "password_require_special" => true, "password_require_unbreached" => true, "password_requirements_apply_to_bundles" => true, "password_validity_days" => 1, "phone" => "555-555-5555", "pin_all_remote_servers_to_site_region" => true, "prevent_root_permissions_for_non_site_admins" => true, "protocol_access_groups_only" => true, "require_2fa" => true, "require_2fa_stop_time" => "2000-01-01T01:00:00Z", "revoke_bundle_access_on_disable_or_delete" => true, "require_2fa_user_type" => "`site_admins`", "require_logout_from_bundles_and_inboxes" => true, "session" => { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => false, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "two_factor_setup_needed" => false, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => false, "user_belongs_to_parent_site" => false, "impersonator_user_id" => 1 }, "sftp_enabled" => true, "sftp_host_key_type" => "default", "active_sftp_host_key_id" => 1, "sftp_insecure_ciphers" => true, "sftp_insecure_diffie_hellman" => true, "sftp_user_root_enabled" => true, "sharing_enabled" => true, "show_user_notifications_log_in_link" => true, "show_request_access_link" => true, "site_footer" => "example", "site_header" => "example", "site_public_footer" => "example", "site_public_header" => "example", "smtp_address" => "smtp.my-mail-server.com", "smtp_authentication" => "plain", "smtp_from" => "me@my-mail-server.com", "smtp_port" => 25, "smtp_username" => "mail", "session_expiry" => 6.0, "session_expiry_minutes" => 360, "snapshot_sharing_enabled" => true, "ssl_required" => true, "subdomain" => "mysite", "switch_to_plan_date" => "2000-01-01T01:00:00Z", "trial_days_left" => 1, "trial_until" => "2000-01-01T01:00:00Z", "use_dedicated_ips_for_smtp" => true, "use_provided_modified_at" => true, "user" => { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => false, "bypass_site_allowed_ips" => false, "bypass_user_lifecycle_rules" => false, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "updated_at" => "2000-01-01T01:00:00Z", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z", "has_reassignable_associations" => true }, "user_lockout" => true, "user_lockout_lock_period" => 1, "user_lockout_tries" => 1, "user_lockout_within" => 6, "user_requests_enabled" => true, "user_requests_notify_admins" => true, "users_can_create_api_keys" => true, "users_can_create_ssh_keys" => true, "welcome_custom_text" => "Welcome to my site!", "welcome_email_cc" => "example", "welcome_email_subject" => "example", "welcome_email_enabled" => true, "welcome_screen" => "user_controlled", "windows_mode_ftp" => true, "group_admins_can_set_user_password" => true, "managed_site_settings" => [ "example" ] }
    end

    get "/api/rest/v1/site/usage" do
      status 200
      { "id" => 1, "start_at" => "2000-01-01T01:00:00Z", "end_at" => "2000-01-01T01:00:00Z", "high_water_user_count" => 1, "current_storage" => 1.0, "high_water_storage" => 1.0, "root_storage" => 1.0, "deleted_files_counted_in_minimum" => 1.0, "deleted_files_storage" => 1.0, "total_billable_usage" => 1.0, "total_billable_transfer_usage" => 1.0, "bytes_sent" => 1.0, "sync_bytes_received" => 1.0, "sync_bytes_sent" => 1.0, "usage_by_top_level_dir" => [ { "dir" => "dir", "size" => 100, "count" => 10 } ] }
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
      optional :welcome_email_enabled, type: Boolean
      optional :ask_about_overwrites, type: Boolean
      optional :show_request_access_link, type: Boolean
      optional :always_mkdir_parents, type: Boolean
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
      optional :office_integration_type, type: String
      optional :pin_all_remote_servers_to_site_region, type: Boolean
      optional :motd_text, type: String
      optional :motd_use_for_ftp, type: Boolean
      optional :motd_use_for_sftp, type: Boolean
      optional :left_navigation_visibility, type: Hash
      optional :additional_text_file_types, type: [ String ]
      optional :bundle_require_note, type: Boolean
      optional :bundle_send_shared_receipts, type: Boolean
      optional :calculate_file_checksums_crc32, type: Boolean
      optional :calculate_file_checksums_md5, type: Boolean
      optional :calculate_file_checksums_sha1, type: Boolean
      optional :calculate_file_checksums_sha256, type: Boolean
      optional :legacy_checksums_mode, type: Boolean
      optional :migrate_remote_server_sync_to_sync, type: Boolean
      optional :session_expiry, type: Float
      optional :ssl_required, type: Boolean
      optional :sftp_insecure_ciphers, type: Boolean
      optional :sftp_insecure_diffie_hellman, type: Boolean
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
      optional :require_logout_from_bundles_and_inboxes, type: Boolean
      optional :dav_user_root_enabled, type: Boolean
      optional :sftp_user_root_enabled, type: Boolean
      optional :disable_password_reset, type: Boolean
      optional :immutable_files, type: Boolean
      optional :bundle_not_found_message, type: String
      optional :bundle_password_required, type: Boolean
      optional :bundle_require_registration, type: Boolean
      optional :bundle_require_share_recipient, type: Boolean
      optional :bundle_registration_notifications, type: String
      optional :bundle_activity_notifications, type: String
      optional :bundle_upload_receipt_notifications, type: String
      optional :document_edits_in_bundle_allowed, type: Boolean
      optional :password_requirements_apply_to_bundles, type: Boolean
      optional :prevent_root_permissions_for_non_site_admins, type: Boolean
      optional :opt_out_global, type: Boolean
      optional :use_provided_modified_at, type: Boolean
      optional :custom_namespace, type: Boolean
      optional :non_sso_groups_allowed, type: Boolean
      optional :non_sso_users_allowed, type: Boolean
      optional :sharing_enabled, type: Boolean
      optional :snapshot_sharing_enabled, type: Boolean
      optional :user_requests_enabled, type: Boolean
      optional :user_requests_notify_admins, type: Boolean
      optional :dav_enabled, type: Boolean
      optional :ftp_enabled, type: Boolean
      optional :sftp_enabled, type: Boolean
      optional :users_can_create_api_keys, type: Boolean
      optional :users_can_create_ssh_keys, type: Boolean
      optional :show_user_notifications_log_in_link, type: Boolean
      optional :sftp_host_key_type, type: String
      optional :active_sftp_host_key_id, type: Integer
      optional :protocol_access_groups_only, type: Boolean
      optional :revoke_bundle_access_on_disable_or_delete, type: Boolean
      optional :bundle_watermark_value, type: Hash
      optional :group_admins_can_set_user_password, type: Boolean
      optional :bundle_recipient_blacklist_free_email_domains, type: Boolean
      optional :bundle_recipient_blacklist_domains, type: [ String ]
      optional :admins_bypass_locked_subfolders, type: Boolean
      optional :allowed_2fa_method_sms, type: Boolean
      optional :allowed_2fa_method_totp, type: Boolean
      optional :allowed_2fa_method_webauthn, type: Boolean
      optional :allowed_2fa_method_yubi, type: Boolean
      optional :allowed_2fa_method_email, type: Boolean
      optional :allowed_2fa_method_static, type: Boolean
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
      optional :site_public_header, type: String
      optional :site_public_footer, type: String
      optional :login_help_text, type: String
      optional :use_dedicated_ips_for_smtp, type: Boolean
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
      optional :uploads_via_email_authentication, type: Boolean
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
      optional :login_page_background_image_file, type: File
      optional :login_page_background_image_delete, type: Boolean
      optional :disable_2fa_with_delay, type: Boolean
      optional :ldap_password_change, type: String
      optional :ldap_password_change_confirmation, type: String
      optional :smtp_password, type: String
      optional :session_expiry_minutes, type: Integer
    end
    patch "/api/rest/v1/site" do
      status 200
      { "id" => 1, "name" => "My Site", "additional_text_file_types" => [ "example" ], "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "allowed_2fa_method_email" => true, "allowed_2fa_method_static" => true, "allowed_2fa_method_bypass_for_ftp_sftp_dav" => true, "admin_user_id" => 1, "admins_bypass_locked_subfolders" => true, "allow_bundle_names" => true, "allowed_countries" => "US,DE", "allowed_ips" => "example", "always_mkdir_parents" => true, "ask_about_overwrites" => true, "bundle_activity_notifications" => "never", "bundle_expiration" => 1, "bundle_not_found_message" => "example", "bundle_password_required" => true, "bundle_recipient_blacklist_domains" => [ "example" ], "bundle_recipient_blacklist_free_email_domains" => true, "bundle_registration_notifications" => "never", "bundle_require_registration" => true, "bundle_require_share_recipient" => true, "bundle_require_note" => true, "bundle_send_shared_receipts" => true, "bundle_upload_receipt_notifications" => "never", "bundle_watermark_attachment" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "bundle_watermark_value" => { "key" => "example value" }, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "uploads_via_email_authentication" => true, "color2_left" => "#0066a7", "color2_link" => "#d34f5d", "color2_text" => "#0066a7", "color2_top" => "#000000", "color2_top_text" => "#ffffff", "contact_name" => "John Doe", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "custom_namespace" => true, "dav_enabled" => true, "dav_user_root_enabled" => true, "days_to_retain_backups" => 30, "document_edits_in_bundle_allowed" => true, "default_time_zone" => "Pacific Time (US & Canada)", "desktop_app" => true, "desktop_app_session_ip_pinning" => true, "desktop_app_session_lifetime" => 1, "legacy_checksums_mode" => true, "migrate_remote_server_sync_to_sync" => true, "mobile_app" => true, "mobile_app_session_ip_pinning" => true, "mobile_app_session_lifetime" => 1, "disallowed_countries" => "US,DE", "disable_files_certificate_generation" => true, "disable_notifications" => true, "disable_password_reset" => true, "domain" => "my-custom-domain.com", "domain_hsts_header" => true, "domain_letsencrypt_chain" => "example", "email" => "john.doe@files.com", "ftp_enabled" => true, "reply_to_email" => "jane.doe@files.com", "non_sso_groups_allowed" => true, "non_sso_users_allowed" => true, "folder_permissions_groups_only" => true, "hipaa" => true, "icon128" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon16" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon32" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "icon48" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "immutable_files_set_at" => "2000-01-01T01:00:00Z", "include_password_in_welcome_email" => true, "language" => "en", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "ldap_enabled" => true, "ldap_group_action" => "disabled", "ldap_group_exclusion" => "example", "ldap_group_inclusion" => "example", "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_type" => "open_ldap", "ldap_user_action" => "disabled", "ldap_user_include_groups" => "example", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName", "login_help_text" => "Login page help text.", "logo" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "login_page_background_image" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "max_prior_passwords" => 1, "motd_text" => "example", "motd_use_for_ftp" => true, "motd_use_for_sftp" => true, "next_billing_amount" => 1.0, "next_billing_date" => "Apr 20", "office_integration_available" => true, "office_integration_type" => "example", "oncehub_link" => "https://go.oncehub.com/files", "opt_out_global" => true, "overdue" => true, "password_min_length" => 1, "password_require_letter" => true, "password_require_mixed" => true, "password_require_number" => true, "password_require_special" => true, "password_require_unbreached" => true, "password_requirements_apply_to_bundles" => true, "password_validity_days" => 1, "phone" => "555-555-5555", "pin_all_remote_servers_to_site_region" => true, "prevent_root_permissions_for_non_site_admins" => true, "protocol_access_groups_only" => true, "require_2fa" => true, "require_2fa_stop_time" => "2000-01-01T01:00:00Z", "revoke_bundle_access_on_disable_or_delete" => true, "require_2fa_user_type" => "`site_admins`", "require_logout_from_bundles_and_inboxes" => true, "session" => { "id" => "60525f92e859c4c3d74cb02fd176b1525901b525", "language" => "en", "login_token" => "@tok-randomcode", "login_token_domain" => "https://mysite.files.com", "max_dir_listing_size" => 1, "multiple_regions" => true, "read_only" => true, "root_path" => "example", "home_path" => "example", "sftp_insecure_ciphers" => false, "site_id" => 1, "ssl_required" => true, "timeout_at" => "2000-01-01T01:00:00Z", "two_factor_setup_needed" => false, "allowed_2fa_method_sms" => true, "allowed_2fa_method_totp" => true, "allowed_2fa_method_webauthn" => true, "allowed_2fa_method_yubi" => true, "calculate_file_checksums_crc32" => true, "calculate_file_checksums_md5" => true, "calculate_file_checksums_sha1" => true, "calculate_file_checksums_sha256" => true, "legacy_checksums_mode" => true, "use_provided_modified_at" => true, "windows_mode_ftp" => false, "user_belongs_to_parent_site" => false, "impersonator_user_id" => 1 }, "sftp_enabled" => true, "sftp_host_key_type" => "default", "active_sftp_host_key_id" => 1, "sftp_insecure_ciphers" => true, "sftp_insecure_diffie_hellman" => true, "sftp_user_root_enabled" => true, "sharing_enabled" => true, "show_user_notifications_log_in_link" => true, "show_request_access_link" => true, "site_footer" => "example", "site_header" => "example", "site_public_footer" => "example", "site_public_header" => "example", "smtp_address" => "smtp.my-mail-server.com", "smtp_authentication" => "plain", "smtp_from" => "me@my-mail-server.com", "smtp_port" => 25, "smtp_username" => "mail", "session_expiry" => 6.0, "session_expiry_minutes" => 360, "snapshot_sharing_enabled" => true, "ssl_required" => true, "subdomain" => "mysite", "switch_to_plan_date" => "2000-01-01T01:00:00Z", "trial_days_left" => 1, "trial_until" => "2000-01-01T01:00:00Z", "use_dedicated_ips_for_smtp" => true, "use_provided_modified_at" => true, "user" => { "id" => 1, "username" => "user", "admin_group_ids" => [ 1 ], "allowed_ips" => "10.0.0.0/8\n127.0.0.1", "attachments_permission" => true, "api_keys_count" => 1, "authenticate_until" => "2000-01-01T01:00:00Z", "authentication_method" => "password", "avatar_url" => "example", "billable" => true, "billing_permission" => false, "bypass_site_allowed_ips" => false, "bypass_user_lifecycle_rules" => false, "created_at" => "2000-01-01T01:00:00Z", "dav_permission" => true, "disabled" => true, "disabled_expired_or_inactive" => true, "email" => "john.doe@files.com", "first_login_at" => "2000-01-01T01:00:00Z", "ftp_permission" => true, "group_ids" => "example", "header_text" => "User-specific message.", "language" => "en", "last_login_at" => "2000-01-01T01:00:00Z", "last_web_login_at" => "2000-01-01T01:00:00Z", "last_ftp_login_at" => "2000-01-01T01:00:00Z", "last_sftp_login_at" => "2000-01-01T01:00:00Z", "last_dav_login_at" => "2000-01-01T01:00:00Z", "last_desktop_login_at" => "2000-01-01T01:00:00Z", "last_restapi_login_at" => "2000-01-01T01:00:00Z", "last_api_use_at" => "2000-01-01T01:00:00Z", "last_active_at" => "2000-01-01T01:00:00Z", "last_protocol_cipher" => "example", "lockout_expires" => "2000-01-01T01:00:00Z", "name" => "John Doe", "company" => "ACME Corp.", "notes" => "Internal notes on this user.", "notification_daily_send_time" => 18, "office_integration_enabled" => true, "password_set_at" => "2000-01-01T01:00:00Z", "password_validity_days" => 1, "public_keys_count" => 1, "receive_admin_alerts" => true, "require_2fa" => "always_require", "require_login_by" => "2000-01-01T01:00:00Z", "active_2fa" => true, "require_password_change" => true, "password_expired" => true, "readonly_site_admin" => true, "restapi_permission" => true, "self_managed" => true, "sftp_permission" => true, "site_admin" => true, "site_id" => 1, "skip_welcome_screen" => true, "ssl_required" => "always_require", "sso_strategy_id" => 1, "subscribe_to_newsletter" => true, "externally_managed" => true, "time_zone" => "Pacific Time (US & Canada)", "type_of_2fa" => "yubi", "type_of_2fa_for_display" => "yubi", "updated_at" => "2000-01-01T01:00:00Z", "user_root" => "example", "user_home" => "example", "days_remaining_until_password_expire" => 1, "password_expire_at" => "2000-01-01T01:00:00Z", "has_reassignable_associations" => true }, "user_lockout" => true, "user_lockout_lock_period" => 1, "user_lockout_tries" => 1, "user_lockout_within" => 6, "user_requests_enabled" => true, "user_requests_notify_admins" => true, "users_can_create_api_keys" => true, "users_can_create_ssh_keys" => true, "welcome_custom_text" => "Welcome to my site!", "welcome_email_cc" => "example", "welcome_email_subject" => "example", "welcome_email_enabled" => true, "welcome_screen" => "user_controlled", "windows_mode_ftp" => true, "group_admins_can_set_user_password" => true, "managed_site_settings" => [ "example" ] }
    end
  end
end
