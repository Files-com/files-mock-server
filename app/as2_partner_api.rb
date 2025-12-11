module FilesMockServer
  class As2PartnerAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/as2_partners" do
      status 200
      [ { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "example", "server_certificate" => "require_match", "http_auth_username" => "username", "additional_http_headers" => { "key" => "example value" }, "default_mime_type" => "application/octet-stream", "mdn_validation_level" => "none", "signature_validation_level" => "normal", "enable_dedicated_ips" => true, "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate" => "example", "public_certificate_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/as2_partners/:id" do
      status 200
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "example", "server_certificate" => "require_match", "http_auth_username" => "username", "additional_http_headers" => { "key" => "example value" }, "default_mime_type" => "application/octet-stream", "mdn_validation_level" => "none", "signature_validation_level" => "normal", "enable_dedicated_ips" => true, "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate" => "example", "public_certificate_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example" }
    end

    params do
      optional :enable_dedicated_ips, type: Boolean
      optional :http_auth_username, type: String
      optional :http_auth_password, type: String
      optional :mdn_validation_level, type: String
      optional :signature_validation_level, type: String
      optional :server_certificate, type: String
      optional :default_mime_type, type: String
      optional :additional_http_headers, type: Hash
      requires :as2_station_id, type: Integer
      requires :name, type: String
      requires :uri, type: String
      requires :public_certificate, type: String
    end
    post "/api/rest/v1/as2_partners" do
      status 201
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "example", "server_certificate" => "require_match", "http_auth_username" => "username", "additional_http_headers" => { "key" => "example value" }, "default_mime_type" => "application/octet-stream", "mdn_validation_level" => "none", "signature_validation_level" => "normal", "enable_dedicated_ips" => true, "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate" => "example", "public_certificate_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :enable_dedicated_ips, type: Boolean
      optional :http_auth_username, type: String
      optional :http_auth_password, type: String
      optional :mdn_validation_level, type: String
      optional :signature_validation_level, type: String
      optional :server_certificate, type: String
      optional :default_mime_type, type: String
      optional :additional_http_headers, type: Hash
      optional :name, type: String
      optional :uri, type: String
      optional :public_certificate, type: String
    end
    patch "/api/rest/v1/as2_partners/:id" do
      status 200
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "example", "server_certificate" => "require_match", "http_auth_username" => "username", "additional_http_headers" => { "key" => "example value" }, "default_mime_type" => "application/octet-stream", "mdn_validation_level" => "none", "signature_validation_level" => "normal", "enable_dedicated_ips" => true, "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate" => "example", "public_certificate_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/as2_partners/:id" do
      status 204
      body false
    end
  end
end
