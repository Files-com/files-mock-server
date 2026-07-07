module FilesMockServer
  class UserCipherUseAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/user_cipher_uses" do
      status 200
      [ { "id" => 1, "user_id" => 1, "username" => "example", "protocol_cipher" => "TLSv1.2; ECDHE-RSA-AES256-GCM-SHA384", "created_at" => "2000-01-01T01:00:00Z", "insecure" => true, "interface" => "restapi", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :user_id, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    post "/api/rest/v1/user_cipher_uses/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
