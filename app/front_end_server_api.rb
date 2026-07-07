module FilesMockServer
  class FrontEndServerAPI < Grape::API
    format :json

    params do
      requires :name, type: String
      optional :hostname, type: String
      optional :zone, type: String
      optional :ips, type: [ String ]
      optional "ips[private_ip]", type: [ String ]
      optional "ips[public_ip]", type: [ String ]
      optional :primary_ip, type: String
      optional :primary_ip_public, type: String
      optional :soo_ip, type: String
      optional :soo_ip_public, type: String
      optional :exavault_ip, type: String
      optional :exavault_ip_public, type: String
      optional :exavault_soo_ip, type: String
      optional :exavault_soo_ip_public, type: String
      optional :smartfile_ip, type: String
      optional :smartfile_ip_public, type: String
      optional :smartfile_soo_ip, type: String
      optional :smartfile_soo_ip_public, type: String
    end
    post "/api/rest/v1/front_end_servers" do
      status 201
      { "ip" => "example", "external_ip" => "example", "assigned" => true, "site" => { "name" => "example", "certificate" => "example", "private_key" => "example", "key" => "example", "intermediates" => "example", "id" => 1, "domain_hsts_header" => true, "ftps_enabled" => true, "https_enabled" => true, "sftp_insecure_ciphers" => true, "tls_disabled" => true, "subdomain" => "example", "domains" => [ "example" ] }, "ftp_enabled" => true, "sftp_enabled" => true, "sftp_host_key_type" => "example", "sftp_host_key_private_key" => "example", "site_id" => 1, "motd_text" => "example", "motd_use_for_ftp" => true, "motd_use_for_sftp" => true, "custom_domains" => [ { "id" => 1, "domain" => "example", "destination" => "example", "ssl_certificate_id" => 1, "certificate" => "example", "private_key" => "example", "intermediates" => "example" } ], "pair_type" => "example" }
    end
  end
end
