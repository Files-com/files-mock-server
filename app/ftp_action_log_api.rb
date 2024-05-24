module FilesMockServer
  class FtpActionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/ftp_action_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "remote_ip" => "example", "server_ip" => "example", "username" => "example", "session_uuid" => "example", "seq_id" => 1, "auth_ciphers" => "example", "action_type" => "example", "path" => "example", "true_path" => "example", "name" => "example", "cmd" => "example", "param" => "example", "responseCode" => "example", "responseMessage" => "example", "entries_returned" => 1, "success" => true, "duration_ms" => 1 } ]
    end
  end
end
