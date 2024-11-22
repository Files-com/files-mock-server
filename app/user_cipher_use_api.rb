module FilesMockServer
  class UserCipherUseAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_cipher_uses" do
      status 200
      [ { "id" => 1, "protocol_cipher" => "TLSv1.2; ECDHE-RSA-AES256-GCM-SHA384", "created_at" => "2000-01-01T01:00:00Z", "insecure" => true, "interface" => "restapi", "updated_at" => "2000-01-01T01:00:00Z", "user_id" => 1 } ]
    end

    params do
      optional :user_id, type: Integer
    end
    post "/api/rest/v1/user_cipher_uses/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
