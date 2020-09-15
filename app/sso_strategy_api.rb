module FilesMockServer
  class SsoStrategyAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
    end
    get "/api/rest/v1/sso_strategies" do
      status 200
      [ { "protocol" => [], "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "saml_provider_cert_fingerprint" => "", "saml_provider_issuer_url" => "", "saml_provider_metadata_content" => "", "saml_provider_metadata_url" => "", "saml_provider_slo_target_url" => "", "saml_provider_sso_target_url" => "", "scim_authentication_method" => "", "scim_username" => "", "subdomain" => "my-site", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "ldap_base_dn" => "", "ldap_domain" => "mysite.com", "enabled" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/sso_strategies/:id" do
      status 200
      { "protocol" => [], "provider" => "okta", "label" => "My Corporate SSO Provider", "logo_url" => "https://mysite.files.com/.../logo.png", "id" => 1, "saml_provider_cert_fingerprint" => "", "saml_provider_issuer_url" => "", "saml_provider_metadata_content" => "", "saml_provider_metadata_url" => "", "saml_provider_slo_target_url" => "", "saml_provider_sso_target_url" => "", "scim_authentication_method" => "", "scim_username" => "", "subdomain" => "my-site", "provision_users" => true, "provision_groups" => true, "deprovision_users" => true, "deprovision_groups" => true, "deprovision_behavior" => "disable", "provision_group_default" => "Employees", "provision_group_exclusion" => "Employees", "provision_group_inclusion" => "Employees", "provision_group_required" => "", "provision_attachments_permission" => true, "provision_dav_permission" => true, "provision_ftp_permission" => true, "provision_sftp_permission" => true, "provision_time_zone" => "Eastern Time (US & Canada)", "provision_company" => "ACME Corp.", "ldap_base_dn" => "", "ldap_domain" => "mysite.com", "enabled" => true, "ldap_host" => "ldap.site.com", "ldap_host_2" => "ldap2.site.com", "ldap_host_3" => "ldap3.site.com", "ldap_port" => 1, "ldap_secure" => true, "ldap_username" => "[ldap username]", "ldap_username_field" => "sAMAccountName" }
    end
  end
end
