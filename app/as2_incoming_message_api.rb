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
      [ { "id" => 1, "as2_partner_id" => 1, "as2_station_id" => 1, "uuid" => "", "content_type" => "", "http_headers" => "", "activity_log" => "", "processing_result" => "", "mic" => "", "mic_algo" => "", "as2_to" => "", "as2_from" => "", "message_id" => "", "subject" => "", "date" => "", "body_size" => "", "attachment_filename" => "", "ip" => "", "created_at" => "2000-01-01T01:00:00Z", "http_response_code" => "", "http_response_headers" => "", "recipient_serial" => "", "hex_recipient_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "recipient_issuer" => "", "message_received" => true, "message_decrypted" => true, "message_signature_verified" => true, "message_processing_success" => true, "message_mdn_returned" => true, "encrypted_uri" => "", "smime_signed_uri" => "", "smime_uri" => "", "raw_uri" => "", "mdn_response_uri" => "" } ]
    end
  end
end
