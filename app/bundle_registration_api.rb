module FilesMockServer
  class BundleRegistrationAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :bundle_id, type: Integer
    end
    get "/api/rest/v1/bundle_registrations" do
      status 200
      [ { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "inbox_code" => "abc123", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "bundle_code" => "example", "bundle_id" => 1, "bundle_recipient_id" => 1, "workspace_id" => 1, "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :bundle_recipient_registration_code, type: String
      optional :password, type: String
      optional :company, type: String
      optional :email, type: String
      optional :name, type: String
      requires :bundle_code, type: String
    end
    post "/api/rest/v1/bundle_registrations" do
      status 201
      { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "inbox_code" => "abc123", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "bundle_code" => "example", "bundle_id" => 1, "bundle_recipient_id" => 1, "workspace_id" => 1, "created_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :bundle_registration_code, type: String
      optional :upload_in_progress, type: Boolean
    end
    post "/api/rest/v1/bundle_registrations/last_activity" do
      status 204
      body false
    end

    params do
      optional :user_id, type: Integer
      optional :sort_by, type: Hash
      optional :bundle_id, type: Integer
    end
    post "/api/rest/v1/bundle_registrations/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
