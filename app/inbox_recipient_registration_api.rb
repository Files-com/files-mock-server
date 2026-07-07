module FilesMockServer
  class InboxRecipientRegistrationAPI < Grape::API
    format :json

    params do
      requires :inbox_recipient_code, type: String
    end
    post "/api/rest/v1/inbox_recipient_registrations" do
      status 201
      { "code" => "example", "inbox_registration_code" => "example", "recipient" => "example", "name" => "example", "company" => "example" }
    end
  end
end
