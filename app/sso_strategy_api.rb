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
      [ { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "my-site", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sso_strategies/:id" do
      status 200
      { "protocol" => "oauth2", "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "user_count" => 1, "saml_provider_cert_fingerprint" => "example", "saml_provider_issuer_url" => "example", "saml_provider_metadata_content" => "example", "saml_provider_metadata_url" => "example", "saml_provider_slo_target_url" => "example", "saml_provider_sso_target_url" => "example", "scim_authentication_method" => "example", "scim_username" => "example", "scim_oauth_access_token" => "example", "scim_oauth_access_token_expires_at" => "example", "subdomain" => "my-site", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "example", "provision_email_signup_groups" => "Employees", "provision_site_admin_groups" => "Employees", "provision_group_admin_groups" => "Employees", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "provision_require_2fa" => "always_require", "ldap_base_dn" => "example", "ldap_domain" => "mysite.com", "enabled" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/sso_strategies/:id/sync" do
      status 204
      body false
    end
  end
end
