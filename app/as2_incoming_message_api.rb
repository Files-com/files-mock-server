module FilesMockServer
  class As2IncomingMessageAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :as2_partner_id, type: Integer
    end
    get "/api/rest/v1/as2_incoming_messages" do
      status 200
      [ { "id" => 1, "as2_partner_id" => 1, "as2_station_id" => 1, "uuid" => "example", "content_type" => "example", "http_headers" => { "key" => "example value" }, "activity_log" => "example", "processing_result" => "example", "processing_result_description" => "example", "mic" => "example", "mic_algo" => "example", "as2_to" => "example", "as2_from" => "example", "message_id" => "example", "subject" => "example", "date" => "example", "body_size" => "example", "attachment_filename" => "example", "ip" => "example", "created_at" => "2000-01-01T01:00:00Z", "http_response_code" => "example", "http_response_headers" => { "key" => "example value" }, "recipient_serial" => "example", "hex_recipient_serial" => "A5:EB:C1:95:DC:D8:2B:E7", "recipient_issuer" => "example", "message_received" => true, "message_decrypted" => true, "message_signature_verified" => true, "message_processing_success" => true, "message_mdn_returned" => true, "encrypted_uri" => "example", "smime_signed_uri" => "example", "smime_uri" => "example", "raw_uri" => "example", "mdn_response_uri" => "example" } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :as2_partner_id, type: Integer
    end
    post "/api/rest/v1/as2_incoming_messages/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
