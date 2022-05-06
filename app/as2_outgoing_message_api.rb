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
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :as2_partner_id, type: Integer
    end
    get "/api/rest/v1/as2_outgoing_messages" do
      status 200
      [ { "id" => 1, "as2_partner_id" => 1, "as2_station_id" => 1, "uuid" => "", "http_headers" => "", "activity_log" => "", "processing_result" => "", "processing_result_description" => "", "mic" => "", "mic_sha_256" => "", "as2_to" => "", "as2_from" => "", "date" => "", "message_id" => "", "body_size" => "", "attachment_filename" => "", "created_at" => "2000-01-01T01:00:00Z", "http_response_code" => "", "http_response_headers" => "", "http_transmission_duration" => 1.0, "mdn_received" => true, "mdn_valid" => true, "mdn_signature_verified" => true, "mdn_message_id_matched" => true, "mdn_mic_matched" => true, "mdn_processing_success" => true, "raw_uri" => "", "smime_uri" => "", "smime_signed_uri" => "", "encrypted_uri" => "", "mdn_response_uri" => "" } ]
    end
  end
end
