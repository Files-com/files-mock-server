module FilesMockServer
  class InboxRegistrationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :folder_behavior_id, type: Integer
    end
    get "/api/rest/v1/inbox_registrations" do
      status 200
      [ { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "inbox_id" => 1, "inbox_recipient_id" => 1, "inbox_title" => "example", "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :folder_behavior_id, type: Integer
    end
    post "/api/rest/v1/inbox_registrations/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
