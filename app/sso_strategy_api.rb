module FilesMockServer
  class SsoStrategyAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/sso_strategies" do
      status 200
      [ { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_readonly_site_admin_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "provision_filesystem_layout" => "integration_centric", "provider_identifier" => "", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "display_on_login_page" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_provisioning_enabled" => true, "ldap_secure" => true, "ldap_type" => "active_directory", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sso_strategies/:id" do
      status 200
      { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_readonly_site_admin_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "provision_filesystem_layout" => "integration_centric", "provider_identifier" => "", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "display_on_login_page" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_provisioning_enabled" => true, "ldap_secure" => true, "ldap_type" => "active_directory", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" }
    end

    params do
      optional :client_id, type: String
      optional :client_secret, type: String
      optional :ldap_password, type: String
      optional :logo_delete, type: Boolean
      optional :logo_file, type: File
      optional :reset_scim_oauth_access_token, type: Boolean
      optional :scim_password, type: String
      optional :deprovision_behavior, type: String
      optional :deprovision_groups, type: Boolean
      optional :deprovision_users, type: Boolean
      optional :display_on_login_page, type: Boolean
      optional :enabled, type: Boolean
      optional :label, type: String
      optional :ldap_base_dn, type: String
      optional :ldap_domain, type: String
      optional :ldap_host, type: String
      optional :ldap_host_2, type: String
      optional :ldap_host_3, type: String
      optional :ldap_port, type: Integer
      optional :ldap_provisioning_enabled, type: Boolean
      optional :ldap_secure, type: Boolean
      optional :ldap_type, type: String
      optional :ldap_username, type: String
      optional :ldap_username_field, type: String
      optional :protocol, type: String
      optional :provider, type: String
      optional :provider_identifier, type: String
      optional :provision_company, type: String
      optional :provision_dav_permission, type: Boolean
      optional :provision_email_signup_groups, type: String
      optional :provision_filesystem_layout, type: String
      optional :provision_ftp_permission, type: Boolean
      optional :provision_group_admin_groups, type: String
      optional :provision_group_default, type: String
      optional :provision_group_exclusion, type: String
      optional :provision_group_inclusion, type: String
      optional :provision_group_required, type: String
      optional :provision_groups, type: Boolean
      optional :provision_readonly_site_admin_groups, type: String
      optional :provision_require_2fa, type: String
      optional :provision_sftp_permission, type: Boolean
      optional :provision_site_admin_groups, type: String
      optional :provision_time_zone, type: String
      optional :provision_users, type: Boolean
      optional :saml_provider_cert_fingerprint, type: String
      optional :saml_provider_issuer_url, type: String
      optional :saml_provider_metadata_content, type: String
      optional :saml_provider_metadata_url, type: String
      optional :saml_provider_slo_target_url, type: String
      optional :saml_provider_sso_target_url, type: String
      optional :scim_authentication_method, type: String
      optional :scim_oauth_access_token_expires_at, type: String
      optional :scim_username, type: String
      optional :subdomain, type: String
    end
    post "/api/rest/v1/sso_strategies" do
      status 201
      { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_readonly_site_admin_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "provision_filesystem_layout" => "integration_centric", "provider_identifier" => "", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "display_on_login_page" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_provisioning_enabled" => true, "ldap_secure" => true, "ldap_type" => "active_directory", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/sso_strategies/:id/sync" do
      status 204
      body false
    end

    params do
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/sso_strategies/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :client_id, type: String
      optional :client_secret, type: String
      optional :ldap_password, type: String
      optional :logo_delete, type: Boolean
      optional :logo_file, type: File
      optional :reset_scim_oauth_access_token, type: Boolean
      optional :scim_password, type: String
      optional :deprovision_behavior, type: String
      optional :deprovision_groups, type: Boolean
      optional :deprovision_users, type: Boolean
      optional :display_on_login_page, type: Boolean
      optional :enabled, type: Boolean
      optional :label, type: String
      optional :ldap_base_dn, type: String
      optional :ldap_domain, type: String
      optional :ldap_host, type: String
      optional :ldap_host_2, type: String
      optional :ldap_host_3, type: String
      optional :ldap_port, type: Integer
      optional :ldap_provisioning_enabled, type: Boolean
      optional :ldap_secure, type: Boolean
      optional :ldap_type, type: String
      optional :ldap_username, type: String
      optional :ldap_username_field, type: String
      optional :protocol, type: String
      optional :provider, type: String
      optional :provider_identifier, type: String
      optional :provision_company, type: String
      optional :provision_dav_permission, type: Boolean
      optional :provision_email_signup_groups, type: String
      optional :provision_filesystem_layout, type: String
      optional :provision_ftp_permission, type: Boolean
      optional :provision_group_admin_groups, type: String
      optional :provision_group_default, type: String
      optional :provision_group_exclusion, type: String
      optional :provision_group_inclusion, type: String
      optional :provision_group_required, type: String
      optional :provision_groups, type: Boolean
      optional :provision_readonly_site_admin_groups, type: String
      optional :provision_require_2fa, type: String
      optional :provision_sftp_permission, type: Boolean
      optional :provision_site_admin_groups, type: String
      optional :provision_time_zone, type: String
      optional :provision_users, type: Boolean
      optional :saml_provider_cert_fingerprint, type: String
      optional :saml_provider_issuer_url, type: String
      optional :saml_provider_metadata_content, type: String
      optional :saml_provider_metadata_url, type: String
      optional :saml_provider_slo_target_url, type: String
      optional :saml_provider_sso_target_url, type: String
      optional :scim_authentication_method, type: String
      optional :scim_oauth_access_token_expires_at, type: String
      optional :scim_username, type: String
      optional :subdomain, type: String
    end
    patch "/api/rest/v1/sso_strategies/:id" do
      status 200
      { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_readonly_site_admin_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "provision_filesystem_layout" => "integration_centric", "provider_identifier" => "", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "display_on_login_page" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_provisioning_enabled" => true, "ldap_secure" => true, "ldap_type" => "active_directory", "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/sso_strategies/:id" do
      status 204
      body false
    end
  end
end
