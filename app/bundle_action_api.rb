module FilesMockServer
  class BundleActionAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/bundle_actions" do
      status 200
      [ { "action" => "create", "bundle_registration" => { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "inbox_code" => "abc123", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "bundle_code" => "example", "bundle_id" => 1, "bundle_recipient_id" => 1, "created_at" => "2000-01-01T01:00:00Z" }, "created_at" => "2000-01-01T01:00:00Z", "destination" => "/to_path", "path" => "", "source" => "/from_path", "bundle_registration_id" => 1, "bundle_registration_name" => "John Doe", "bundle_registration_email" => "john@example.com", "bundle_registration_ip" => "127.0.0.1" } ]
    end
  end
end
