module FilesMockServer
  class As2OutgoingMessageAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :as2_partner_id, type: Integer
    end
    get "/api/rest/v1/as2_outgoing_messages" do
      status 200
      [ { "id" => 1, "as2_partner_id" => 1, "uuid" => "", "http_headers" => "", "activity_log" => "", "processing_result" => "", "mic" => "", "message_id" => "", "body_size" => "", "attachment_filename" => "", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
