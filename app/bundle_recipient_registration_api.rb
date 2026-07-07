module FilesMockServer
  class BundleRecipientRegistrationAPI < Grape::API
    format :json

    params do
      requires :bundle_recipient_code, type: String
    end
    post "/api/rest/v1/bundle_recipient_registrations" do
      status 201
      { "code" => "example", "bundle_registration_code" => "example", "recipient" => "example", "name" => "example", "company" => "example", "password_emailed" => true, "inbox_code" => "abc123" }
    end
  end
end
