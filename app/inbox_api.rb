module FilesMockServer
  class InboxAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/inboxes" do
      status 200
      [ { "title" => "example", "description" => "My inbox", "help_text" => "If you need any help submitting your application, please call our front desk.", "key" => "application-form", "show_on_login_page" => true, "has_password" => true, "require_registration" => true, "dont_allow_folders_in_uploads" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true, "in_use" => true }, "notify_senders_on_successful_uploads_via_email" => true, "notify_senders_on_successful_uploads_via_web" => true, "allow_whitelisting" => true, "whitelist" => [ "example" ], "disable_web_upload" => true, "inbound_email_address" => "example" } ]
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/inboxes/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
