module FilesMockServer
  class InboundS3LogAPI < Grape::API
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
    get "/api/rest/v1/inbound_s3_logs" do
      status 200
      [ { "path" => "example", "client_ip" => "example", "operation" => "example", "status" => "example", "aws_access_key" => "example", "error_message" => "example", "error_type" => "example", "duration_ms" => 1, "request_id" => "example", "user_agent" => "example", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
