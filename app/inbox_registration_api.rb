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
      [ { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "inbox_id" => 1, "inbox_recipient_id" => 1, "inbox_title" => "example" } ]
    end
  end
end
