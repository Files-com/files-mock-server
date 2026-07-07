module FilesMockServer
  class UserSftpClientUseAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/user_sftp_client_uses" do
      status 200
      [ { "id" => 1, "sftp_client" => "example", "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "user_id" => 1 } ]
    end
  end
end
