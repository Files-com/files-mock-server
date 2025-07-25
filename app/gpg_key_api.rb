module FilesMockServer
  class GpgKeyAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/gpg_keys" do
      status 200
      [ { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "name" => "key name", "user_id" => 1, "public_key_md5" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key_md5" => "ab236cfe4a195f0226bc2e674afdd6b0", "public_key" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key" => "ab236cfe4a195f0226bc2e674afdd6b0", "private_key_password" => "[your GPG private key password]" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/gpg_keys/:id" do
      status 200
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "name" => "key name", "user_id" => 1, "public_key_md5" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key_md5" => "ab236cfe4a195f0226bc2e674afdd6b0", "public_key" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key" => "ab236cfe4a195f0226bc2e674afdd6b0", "private_key_password" => "[your GPG private key password]" }
    end

    params do
      optional :user_id, type: Integer
      optional :public_key, type: String
      optional :private_key, type: String
      optional :private_key_password, type: String
      requires :name, type: String
      optional :generate_expires_at, type: String
      optional :generate_keypair, type: Boolean
      optional :generate_full_name, type: String
      optional :generate_email, type: String
    end
    post "/api/rest/v1/gpg_keys" do
      status 201
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "name" => "key name", "user_id" => 1, "public_key_md5" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key_md5" => "ab236cfe4a195f0226bc2e674afdd6b0", "public_key" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key" => "ab236cfe4a195f0226bc2e674afdd6b0", "private_key_password" => "[your GPG private key password]" }
    end

    params do
      requires :id, type: Integer
      optional :public_key, type: String
      optional :private_key, type: String
      optional :private_key_password, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/gpg_keys/:id" do
      status 200
      { "id" => 1, "expires_at" => "2000-01-01T01:00:00Z", "name" => "key name", "user_id" => 1, "public_key_md5" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key_md5" => "ab236cfe4a195f0226bc2e674afdd6b0", "public_key" => "7f8bc1210b09b9ddf469e6b6b8920e76", "private_key" => "ab236cfe4a195f0226bc2e674afdd6b0", "private_key_password" => "[your GPG private key password]" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/gpg_keys/:id" do
      status 204
      body false
    end
  end
end
