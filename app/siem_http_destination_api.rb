module FilesMockServer
  class SiemHttpDestinationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/siem_http_destinations" do
      status 200
      [ { "id" => 1, "name" => "example", "destination_type" => "example", "destination_url" => "example", "file_destination_path" => "example", "file_format" => "example", "file_interval_minutes" => 1, "additional_headers" => { "key" => "example value" }, "sending_active" => true, "generic_payload_type" => "example", "splunk_token_masked" => "example", "azure_dcr_immutable_id" => "example", "azure_stream_name" => "example", "azure_oauth_client_credentials_tenant_id" => "example", "azure_oauth_client_credentials_client_id" => "example", "azure_oauth_client_credentials_client_secret_masked" => "example", "qradar_username" => "example", "qradar_password_masked" => "example", "solar_winds_token_masked" => "example", "new_relic_api_key_masked" => "example", "datadog_api_key_masked" => "example", "sftp_action_send_enabled" => true, "sftp_action_entries_sent" => 1, "ftp_action_send_enabled" => true, "ftp_action_entries_sent" => 1, "web_dav_action_send_enabled" => true, "web_dav_action_entries_sent" => 1, "sync_send_enabled" => true, "sync_entries_sent" => 1, "outbound_connection_send_enabled" => true, "outbound_connection_entries_sent" => 1, "automation_send_enabled" => true, "automation_entries_sent" => 1, "api_request_send_enabled" => true, "api_request_entries_sent" => 1, "public_hosting_request_send_enabled" => true, "public_hosting_request_entries_sent" => 1, "email_send_enabled" => true, "email_entries_sent" => 1, "exavault_api_request_send_enabled" => true, "exavault_api_request_entries_sent" => 1, "settings_change_send_enabled" => true, "settings_change_entries_sent" => 1, "last_http_call_target_type" => "destination_url", "last_http_call_success" => true, "last_http_call_response_code" => 1, "last_http_call_response_body" => "example", "last_http_call_error_message" => "example", "last_http_call_time" => "example", "last_http_call_duration_ms" => 1, "most_recent_http_call_success_time" => "example", "connection_test_entry" => "example" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/siem_http_destinations/:id" do
      status 200
      { "id" => 1, "name" => "example", "destination_type" => "example", "destination_url" => "example", "file_destination_path" => "example", "file_format" => "example", "file_interval_minutes" => 1, "additional_headers" => { "key" => "example value" }, "sending_active" => true, "generic_payload_type" => "example", "splunk_token_masked" => "example", "azure_dcr_immutable_id" => "example", "azure_stream_name" => "example", "azure_oauth_client_credentials_tenant_id" => "example", "azure_oauth_client_credentials_client_id" => "example", "azure_oauth_client_credentials_client_secret_masked" => "example", "qradar_username" => "example", "qradar_password_masked" => "example", "solar_winds_token_masked" => "example", "new_relic_api_key_masked" => "example", "datadog_api_key_masked" => "example", "sftp_action_send_enabled" => true, "sftp_action_entries_sent" => 1, "ftp_action_send_enabled" => true, "ftp_action_entries_sent" => 1, "web_dav_action_send_enabled" => true, "web_dav_action_entries_sent" => 1, "sync_send_enabled" => true, "sync_entries_sent" => 1, "outbound_connection_send_enabled" => true, "outbound_connection_entries_sent" => 1, "automation_send_enabled" => true, "automation_entries_sent" => 1, "api_request_send_enabled" => true, "api_request_entries_sent" => 1, "public_hosting_request_send_enabled" => true, "public_hosting_request_entries_sent" => 1, "email_send_enabled" => true, "email_entries_sent" => 1, "exavault_api_request_send_enabled" => true, "exavault_api_request_entries_sent" => 1, "settings_change_send_enabled" => true, "settings_change_entries_sent" => 1, "last_http_call_target_type" => "destination_url", "last_http_call_success" => true, "last_http_call_response_code" => 1, "last_http_call_response_body" => "example", "last_http_call_error_message" => "example", "last_http_call_time" => "example", "last_http_call_duration_ms" => 1, "most_recent_http_call_success_time" => "example", "connection_test_entry" => "example" }
    end

    params do
      optional :name, type: String
      optional :additional_headers, type: Hash
      optional :sending_active, type: Boolean
      optional :generic_payload_type, type: String
      optional :file_destination_path, type: String
      optional :file_format, type: String
      optional :file_interval_minutes, type: Integer
      optional :splunk_token, type: String
      optional :azure_dcr_immutable_id, type: String
      optional :azure_stream_name, type: String
      optional :azure_oauth_client_credentials_tenant_id, type: String
      optional :azure_oauth_client_credentials_client_id, type: String
      optional :azure_oauth_client_credentials_client_secret, type: String
      optional :qradar_username, type: String
      optional :qradar_password, type: String
      optional :solar_winds_token, type: String
      optional :new_relic_api_key, type: String
      optional :datadog_api_key, type: String
      optional :sftp_action_send_enabled, type: Boolean
      optional :ftp_action_send_enabled, type: Boolean
      optional :web_dav_action_send_enabled, type: Boolean
      optional :sync_send_enabled, type: Boolean
      optional :outbound_connection_send_enabled, type: Boolean
      optional :automation_send_enabled, type: Boolean
      optional :api_request_send_enabled, type: Boolean
      optional :public_hosting_request_send_enabled, type: Boolean
      optional :email_send_enabled, type: Boolean
      optional :exavault_api_request_send_enabled, type: Boolean
      optional :settings_change_send_enabled, type: Boolean
      requires :destination_type, type: String
      optional :destination_url, type: String
    end
    post "/api/rest/v1/siem_http_destinations" do
      status 201
      { "id" => 1, "name" => "example", "destination_type" => "example", "destination_url" => "example", "file_destination_path" => "example", "file_format" => "example", "file_interval_minutes" => 1, "additional_headers" => { "key" => "example value" }, "sending_active" => true, "generic_payload_type" => "example", "splunk_token_masked" => "example", "azure_dcr_immutable_id" => "example", "azure_stream_name" => "example", "azure_oauth_client_credentials_tenant_id" => "example", "azure_oauth_client_credentials_client_id" => "example", "azure_oauth_client_credentials_client_secret_masked" => "example", "qradar_username" => "example", "qradar_password_masked" => "example", "solar_winds_token_masked" => "example", "new_relic_api_key_masked" => "example", "datadog_api_key_masked" => "example", "sftp_action_send_enabled" => true, "sftp_action_entries_sent" => 1, "ftp_action_send_enabled" => true, "ftp_action_entries_sent" => 1, "web_dav_action_send_enabled" => true, "web_dav_action_entries_sent" => 1, "sync_send_enabled" => true, "sync_entries_sent" => 1, "outbound_connection_send_enabled" => true, "outbound_connection_entries_sent" => 1, "automation_send_enabled" => true, "automation_entries_sent" => 1, "api_request_send_enabled" => true, "api_request_entries_sent" => 1, "public_hosting_request_send_enabled" => true, "public_hosting_request_entries_sent" => 1, "email_send_enabled" => true, "email_entries_sent" => 1, "exavault_api_request_send_enabled" => true, "exavault_api_request_entries_sent" => 1, "settings_change_send_enabled" => true, "settings_change_entries_sent" => 1, "last_http_call_target_type" => "destination_url", "last_http_call_success" => true, "last_http_call_response_code" => 1, "last_http_call_response_body" => "example", "last_http_call_error_message" => "example", "last_http_call_time" => "example", "last_http_call_duration_ms" => 1, "most_recent_http_call_success_time" => "example", "connection_test_entry" => "example" }
    end

    params do
      optional :siem_http_destination_id, type: Integer
      optional :destination_type, type: String
      optional :destination_url, type: String
      optional :name, type: String
      optional :additional_headers, type: Hash
      optional :sending_active, type: Boolean
      optional :generic_payload_type, type: String
      optional :file_destination_path, type: String
      optional :file_format, type: String
      optional :file_interval_minutes, type: Integer
      optional :splunk_token, type: String
      optional :azure_dcr_immutable_id, type: String
      optional :azure_stream_name, type: String
      optional :azure_oauth_client_credentials_tenant_id, type: String
      optional :azure_oauth_client_credentials_client_id, type: String
      optional :azure_oauth_client_credentials_client_secret, type: String
      optional :qradar_username, type: String
      optional :qradar_password, type: String
      optional :solar_winds_token, type: String
      optional :new_relic_api_key, type: String
      optional :datadog_api_key, type: String
      optional :sftp_action_send_enabled, type: Boolean
      optional :ftp_action_send_enabled, type: Boolean
      optional :web_dav_action_send_enabled, type: Boolean
      optional :sync_send_enabled, type: Boolean
      optional :outbound_connection_send_enabled, type: Boolean
      optional :automation_send_enabled, type: Boolean
      optional :api_request_send_enabled, type: Boolean
      optional :public_hosting_request_send_enabled, type: Boolean
      optional :email_send_enabled, type: Boolean
      optional :exavault_api_request_send_enabled, type: Boolean
      optional :settings_change_send_enabled, type: Boolean
    end
    post "/api/rest/v1/siem_http_destinations/send_test_entry" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :additional_headers, type: Hash
      optional :sending_active, type: Boolean
      optional :generic_payload_type, type: String
      optional :file_destination_path, type: String
      optional :file_format, type: String
      optional :file_interval_minutes, type: Integer
      optional :splunk_token, type: String
      optional :azure_dcr_immutable_id, type: String
      optional :azure_stream_name, type: String
      optional :azure_oauth_client_credentials_tenant_id, type: String
      optional :azure_oauth_client_credentials_client_id, type: String
      optional :azure_oauth_client_credentials_client_secret, type: String
      optional :qradar_username, type: String
      optional :qradar_password, type: String
      optional :solar_winds_token, type: String
      optional :new_relic_api_key, type: String
      optional :datadog_api_key, type: String
      optional :sftp_action_send_enabled, type: Boolean
      optional :ftp_action_send_enabled, type: Boolean
      optional :web_dav_action_send_enabled, type: Boolean
      optional :sync_send_enabled, type: Boolean
      optional :outbound_connection_send_enabled, type: Boolean
      optional :automation_send_enabled, type: Boolean
      optional :api_request_send_enabled, type: Boolean
      optional :public_hosting_request_send_enabled, type: Boolean
      optional :email_send_enabled, type: Boolean
      optional :exavault_api_request_send_enabled, type: Boolean
      optional :settings_change_send_enabled, type: Boolean
      optional :destination_type, type: String
      optional :destination_url, type: String
    end
    patch "/api/rest/v1/siem_http_destinations/:id" do
      status 200
      { "id" => 1, "name" => "example", "destination_type" => "example", "destination_url" => "example", "file_destination_path" => "example", "file_format" => "example", "file_interval_minutes" => 1, "additional_headers" => { "key" => "example value" }, "sending_active" => true, "generic_payload_type" => "example", "splunk_token_masked" => "example", "azure_dcr_immutable_id" => "example", "azure_stream_name" => "example", "azure_oauth_client_credentials_tenant_id" => "example", "azure_oauth_client_credentials_client_id" => "example", "azure_oauth_client_credentials_client_secret_masked" => "example", "qradar_username" => "example", "qradar_password_masked" => "example", "solar_winds_token_masked" => "example", "new_relic_api_key_masked" => "example", "datadog_api_key_masked" => "example", "sftp_action_send_enabled" => true, "sftp_action_entries_sent" => 1, "ftp_action_send_enabled" => true, "ftp_action_entries_sent" => 1, "web_dav_action_send_enabled" => true, "web_dav_action_entries_sent" => 1, "sync_send_enabled" => true, "sync_entries_sent" => 1, "outbound_connection_send_enabled" => true, "outbound_connection_entries_sent" => 1, "automation_send_enabled" => true, "automation_entries_sent" => 1, "api_request_send_enabled" => true, "api_request_entries_sent" => 1, "public_hosting_request_send_enabled" => true, "public_hosting_request_entries_sent" => 1, "email_send_enabled" => true, "email_entries_sent" => 1, "exavault_api_request_send_enabled" => true, "exavault_api_request_entries_sent" => 1, "settings_change_send_enabled" => true, "settings_change_entries_sent" => 1, "last_http_call_target_type" => "destination_url", "last_http_call_success" => true, "last_http_call_response_code" => 1, "last_http_call_response_body" => "example", "last_http_call_error_message" => "example", "last_http_call_time" => "example", "last_http_call_duration_ms" => 1, "most_recent_http_call_success_time" => "example", "connection_test_entry" => "example" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/siem_http_destinations/:id" do
      status 204
      body false
    end
  end
end
