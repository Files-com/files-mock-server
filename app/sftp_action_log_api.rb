module FilesMockServer
  class SftpActionLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/sftp_action_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "remote_ip" => "example", "username" => "example", "session_uid" => "example", "seq_id" => 1, "auth_method" => "example", "auth_ciphers" => "example", "action_type" => "example", "path" => "example", "true_path" => "example", "name" => "example", "message" => "example", "failure_reason_type" => "example", "failure_reason_message" => "example", "md5" => "example", "flags" => "example", "handle" => "example", "attrs" => "example", "size" => "example", "offset" => "example", "length" => "example", "data_length" => "example", "entries_returned" => 1, "success" => "example", "duration_ms" => 1 } ]
    end
  end
end
