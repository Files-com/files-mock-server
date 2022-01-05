module FilesMockServer
  class As2IncomingMessageAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :as2_partner_id, type: Integer
    end
    get "/api/rest/v1/as2_incoming_messages" do
      status 200
      [ { "id" => 1, "as2_partner_id" => 1, "uuid" => "", "content_type" => "", "http_headers" => "", "activity_log" => "", "processing_result" => "", "as2_to" => "", "as2_from" => "", "message_id" => "", "subject" => "", "body_size" => "", "attachment_filename" => "", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
