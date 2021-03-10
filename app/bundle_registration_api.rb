module FilesMockServer
  class BundleRegistrationAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      requires :bundle_id, type: Integer
    end
    get "/api/rest/v1/bundle_registrations" do
      status 200
      [ { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "inbox_code" => "abc123", "form_field_set_id" => 1, "form_field_data" => "" } ]
    end
  end
end
