module FilesMockServer
  class EmailPreferenceAPI < Grape::API
    format :json

    params do
      requires :token, type: String
    end
    get "/api/rest/v1/email_preferences/:token" do
      status 200
      { "email" => "john.doe@files.com", "notifications" => [ { "id" => 1, "path" => "example", "send_interval" => "fifteen_minutes", "unsubscribed" => true } ], "bundle_notifications" => [ { "id" => 1, "bundle_code" => "example", "unsubscribed" => true } ], "receive_admin_alerts" => true, "notify_on_all_site_warnings" => true, "notify_on_all_sso_failures" => true, "notify_on_all_user_security_events" => true, "notify_on_all_pending_work_failures" => true, "notify_on_all_siem_http_destination_failures" => true, "notify_on_all_sync_failures" => true, "notify_on_all_automation_failures" => true, "notify_on_all_expectation_failures" => true, "receive_marketing_mail" => true, "receive_transactional_mail" => true }
    end

    params do
      requires :token, type: String
      optional "user[receive_admin_alerts]", type: Boolean
      optional "user[notify_on_all_site_warnings]", type: Boolean
      optional "user[notify_on_all_sso_failures]", type: Boolean
      optional "user[notify_on_all_user_security_events]", type: Boolean
      optional "user[notify_on_all_pending_work_failures]", type: Boolean
      optional "user[notify_on_all_siem_http_destination_failures]", type: Boolean
      optional "user[notify_on_all_sync_failures]", type: Boolean
      optional "user[notify_on_all_automation_failures]", type: Boolean
      optional "user[notify_on_all_expectation_failures]", type: Boolean
      optional "user[unsubscribe_marketing]", type: Boolean
      optional "user[unsubscribe_transactional]", type: Boolean
      optional "user[unsubscribe]", type: Boolean
      optional "user[notifications][id]", type: [ Integer ]
      optional "user[notifications][group]", type: [ Boolean ]
      optional "user[notifications][send_interval]", type: [ String ]
      optional "user[notifications][unsubscribe]", type: [ Boolean ]
      optional "user[bundle_notifications][id]", type: [ Integer ]
      optional "user[bundle_notifications][unsubscribe]", type: [ Boolean ]
    end
    patch "/api/rest/v1/email_preferences/:token" do
      status 200
      { "email" => "john.doe@files.com", "notifications" => [ { "id" => 1, "path" => "example", "send_interval" => "fifteen_minutes", "unsubscribed" => true } ], "bundle_notifications" => [ { "id" => 1, "bundle_code" => "example", "unsubscribed" => true } ], "receive_admin_alerts" => true, "notify_on_all_site_warnings" => true, "notify_on_all_sso_failures" => true, "notify_on_all_user_security_events" => true, "notify_on_all_pending_work_failures" => true, "notify_on_all_siem_http_destination_failures" => true, "notify_on_all_sync_failures" => true, "notify_on_all_automation_failures" => true, "notify_on_all_expectation_failures" => true, "receive_marketing_mail" => true, "receive_transactional_mail" => true }
    end
  end
end
