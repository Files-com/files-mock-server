module FilesMockServer
  class As2StationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/as2_stations" do
      status 200
      [ { "id" => 1, "name" => "AS2 Station Name", "uri" => "example", "domain" => "domain.test", "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate_md5" => "example", "private_key_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example", "private_key_password_md5" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/as2_stations/:id" do
      status 200
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "example", "domain" => "domain.test", "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate_md5" => "example", "private_key_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example", "private_key_password_md5" => "example" }
    end

    params do
      requires :name, type: String
      requires :public_certificate, type: String
      requires :private_key, type: String
      optional :private_key_password, type: String
    end
    post "/api/rest/v1/as2_stations" do
      status 201
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "example", "domain" => "domain.test", "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate_md5" => "example", "private_key_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example", "private_key_password_md5" => "example" }
    end

    post "/api/rest/v1/as2_stations/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :public_certificate, type: String
      optional :private_key, type: String
      optional :private_key_password, type: String
    end
    patch "/api/rest/v1/as2_stations/:id" do
      status 200
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "example", "domain" => "domain.test", "hex_public_certificate_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "public_certificate_md5" => "example", "private_key_md5" => "example", "public_certificate_subject" => "example", "public_certificate_issuer" => "example", "public_certificate_serial" => "example", "public_certificate_not_before" => "example", "public_certificate_not_after" => "example", "private_key_password_md5" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/as2_stations/:id" do
      status 204
      body false
    end
  end
end
