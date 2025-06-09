module FilesMockServer
  class SftpActionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/sftp_action_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "remote_ip" => "example", "server_ip" => "example", "username" => "example", "ssh_client_identification" => "example", "session_uuid" => "example", "seq_id" => 1, "auth_method" => "example", "auth_ciphers" => "example", "action_type" => "example", "path" => "example", "true_path" => "example", "name" => "example", "sftp_response_code" => "example", "sftp_response_message" => "example", "md5" => "example", "size" => 1, "data_length" => 1, "bytes_transferred" => 1, "entries_returned" => 1, "success" => true, "status" => "example", "duration_ms" => 1, "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
