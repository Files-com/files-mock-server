module FilesMockServer
  class As2StationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/as2_stations" do
      status 200
      [ { "id" => 1, "name" => "AS2 Station Name", "uri" => "", "domain" => "domain.test", "public_certificate_md5" => "", "private_key_md5" => "", "public_certificate_subject" => "", "public_certificate_issuer" => "", "public_certificate_serial" => "", "public_certificate_not_before" => "", "public_certificate_not_after" => "" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/as2_stations/:id" do
      status 200
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "", "domain" => "domain.test", "public_certificate_md5" => "", "private_key_md5" => "", "public_certificate_subject" => "", "public_certificate_issuer" => "", "public_certificate_serial" => "", "public_certificate_not_before" => "", "public_certificate_not_after" => "" }
    end

    params do
      requires :name, type: String
      requires :public_certificate, type: String
      requires :private_key, type: String
    end
    post "/api/rest/v1/as2_stations" do
      status 201
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "", "domain" => "domain.test", "public_certificate_md5" => "", "private_key_md5" => "", "public_certificate_subject" => "", "public_certificate_issuer" => "", "public_certificate_serial" => "", "public_certificate_not_before" => "", "public_certificate_not_after" => "" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :public_certificate, type: String
      optional :private_key, type: String
    end
    patch "/api/rest/v1/as2_stations/:id" do
      status 200
      { "id" => 1, "name" => "AS2 Station Name", "uri" => "", "domain" => "domain.test", "public_certificate_md5" => "", "private_key_md5" => "", "public_certificate_subject" => "", "public_certificate_issuer" => "", "public_certificate_serial" => "", "public_certificate_not_before" => "", "public_certificate_not_after" => "" }
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
