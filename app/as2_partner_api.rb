module FilesMockServer
  class As2PartnerAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/as2_partners" do
      status 200
      [ { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "", "public_certificate_md5" => "" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/as2_partners/:id" do
      status 200
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "", "public_certificate_md5" => "" }
    end

    params do
      requires :name, type: String
      requires :uri, type: String
      requires :public_certificate, type: String
      requires :as2_station_id, type: Integer
    end
    post "/api/rest/v1/as2_partners" do
      status 201
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "", "public_certificate_md5" => "" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :uri, type: String
      optional :public_certificate, type: String
    end
    patch "/api/rest/v1/as2_partners/:id" do
      status 200
      { "id" => 1, "as2_station_id" => 1, "name" => "AS2 Partner Name", "uri" => "", "public_certificate_md5" => "" }
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
