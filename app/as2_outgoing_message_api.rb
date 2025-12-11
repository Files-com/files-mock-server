module FilesMockServer
  class As2OutgoingMessageAPI < Grape::API
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
    end
    get "/api/rest/v1/as2_outgoing_messages" do
      status 200
      [ { "id" => 1, "as2_partner_id" => 1, "as2_station_id" => 1, "uuid" => "example", "http_headers" => { "key" => "example value" }, "processing_result" => "example", "processing_result_description" => "example", "mic" => "example", "mic_sha_256" => "example", "as2_to" => "example", "as2_from" => "example", "date" => "example", "message_id" => "example", "body_size" => "example", "attachment_filename" => "example", "created_at" => "2000-01-01T01:00:00Z", "http_response_code" => "example", "http_response_headers" => { "key" => "example value" }, "http_transmission_duration" => 1.0, "mdn_received" => true, "mdn_valid" => true, "mdn_signature_verified" => true, "mdn_message_id_matched" => true, "mdn_mic_matched" => true, "mdn_processing_success" => true, "raw_uri" => "example", "smime_uri" => "example", "smime_signed_uri" => "example", "encrypted_uri" => "example", "mdn_response_uri" => "example" } ]
    end
  end
end
