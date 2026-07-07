module FilesMockServer
  class CertificateAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/certificates" do
      status 200
      [ { "id" => 1, "name" => "My Certificate", "certificate" => "[certificate]", "created_at" => "2000-01-01T01:00:00Z", "display_status" => "Available", "domains" => [], "expires_at" => "2000-01-01T01:00:00Z", "brick_managed" => true, "intermediates" => "[certificates]", "ip_addresses" => [], "issuer" => "example", "key_type" => "RSA-4096", "request" => "[CSR]", "status" => "Available", "subject" => "my-custom-domain.com" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/certificates/:id" do
      status 200
      { "id" => 1, "name" => "My Certificate", "certificate" => "[certificate]", "created_at" => "2000-01-01T01:00:00Z", "display_status" => "Available", "domains" => [], "expires_at" => "2000-01-01T01:00:00Z", "brick_managed" => true, "intermediates" => "[certificates]", "ip_addresses" => [], "issuer" => "example", "key_type" => "RSA-4096", "request" => "[CSR]", "status" => "Available", "subject" => "my-custom-domain.com" }
    end

    params do
      requires :name, type: String
      optional :certificate_domain, type: String
      optional :certificate_extra_domains, type: [ String ]
      optional :certificate_country, type: String
      optional :certificate_state_or_province, type: String
      optional :certificate_city_or_locale, type: String
      optional :certificate_company_name, type: String
      optional :csr_ou1, type: String
      optional :csr_ou2, type: String
      optional :csr_ou3, type: String
      optional :certificate_email_address, type: String
      optional :key_type, type: String
      optional :certificate, type: String
      optional :private_key, type: String
      optional :password, type: String
      optional :intermediates, type: String
    end
    post "/api/rest/v1/certificates" do
      status 201
      { "id" => 1, "name" => "My Certificate", "certificate" => "[certificate]", "created_at" => "2000-01-01T01:00:00Z", "display_status" => "Available", "domains" => [], "expires_at" => "2000-01-01T01:00:00Z", "brick_managed" => true, "intermediates" => "[certificates]", "ip_addresses" => [], "issuer" => "example", "key_type" => "RSA-4096", "request" => "[CSR]", "status" => "Available", "subject" => "my-custom-domain.com" }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/certificates/:id/deactivate" do
      status 200
      body false
    end

    params do
      requires :id, type: Integer
      optional :replace_cert, type: String
    end
    post "/api/rest/v1/certificates/:id/activate" do
      status 200
      body false
    end

    post "/api/rest/v1/certificates/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :intermediates, type: String
      optional :certificate, type: String
    end
    patch "/api/rest/v1/certificates/:id" do
      status 200
      { "id" => 1, "name" => "My Certificate", "certificate" => "[certificate]", "created_at" => "2000-01-01T01:00:00Z", "display_status" => "Available", "domains" => [], "expires_at" => "2000-01-01T01:00:00Z", "brick_managed" => true, "intermediates" => "[certificates]", "ip_addresses" => [], "issuer" => "example", "key_type" => "RSA-4096", "request" => "[CSR]", "status" => "Available", "subject" => "my-custom-domain.com" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/certificates/:id" do
      status 204
      body false
    end
  end
end
