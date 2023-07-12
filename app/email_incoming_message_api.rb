module FilesMockServer
  class EmailIncomingMessageAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_prefix, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/email_incoming_messages" do
      status 200
      [ { "id" => 1, "inbox_id" => 1, "sender" => "example", "sender_name" => "example", "status" => "success", "body" => "example", "message" => "example", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
