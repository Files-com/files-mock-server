module FilesMockServer
  class AccountAPI < Grape::API
    format :json

    get "/api/rest/v1/account" do
      status 200
      { "name" => "account", "address" => "123 Main St", "address_2" => "Window 1", "card_number" => "xxxxxxxxxxxx1234", "card_type" => "Visa", "city" => "New York", "company_name" => "Action Verb", "country" => "US", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "email" => "john.doe@files.com", "phone_number" => "555-555-5555", "processor_type" => "Credit Card", "state" => "NY", "zip" => "00000", "billing_frequency" => 1 }
    end

    params do
      optional :name, type: String
      optional :company_name, type: String
      optional :address, type: String
      optional :address_2, type: String
      optional :city, type: String
      optional :state, type: String
      optional :zip, type: String
      optional :country, type: String
      optional :email, type: String
      optional :phone_number, type: String
      optional :card_number, type: String
      optional :card_type, type: String
      optional :expiration_year, type: String
      optional :expiration_month, type: String
      optional :start_year, type: String
      optional :start_month, type: String
      optional :cvv, type: String
      optional :paypal_token, type: String
      optional :paypal_payer_id, type: String
      optional :plan_id, type: Integer
      optional :billing_frequency, type: Integer
      optional :currency, type: String
      optional :create_account, type: Boolean
    end
    post "/api/rest/v1/account" do
      status 201
      { "name" => "account", "address" => "123 Main St", "address_2" => "Window 1", "card_number" => "xxxxxxxxxxxx1234", "card_type" => "Visa", "city" => "New York", "company_name" => "Action Verb", "country" => "US", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "email" => "john.doe@files.com", "phone_number" => "555-555-5555", "processor_type" => "Credit Card", "state" => "NY", "zip" => "00000", "billing_frequency" => 1 }
    end

    params do
      optional :name, type: String
      optional :company_name, type: String
      optional :address, type: String
      optional :address_2, type: String
      optional :city, type: String
      optional :state, type: String
      optional :zip, type: String
      optional :country, type: String
      optional :email, type: String
      optional :phone_number, type: String
      optional :card_number, type: String
      optional :card_type, type: String
      optional :expiration_year, type: String
      optional :expiration_month, type: String
      optional :start_year, type: String
      optional :start_month, type: String
      optional :cvv, type: String
      optional :paypal_token, type: String
      optional :paypal_payer_id, type: String
    end
    patch "/api/rest/v1/account" do
      status 200
      { "name" => "account", "address" => "123 Main St", "address_2" => "Window 1", "card_number" => "xxxxxxxxxxxx1234", "card_type" => "Visa", "city" => "New York", "company_name" => "Action Verb", "country" => "US", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "email" => "john.doe@files.com", "phone_number" => "555-555-5555", "processor_type" => "Credit Card", "state" => "NY", "zip" => "00000", "billing_frequency" => 1 }
    end
  end
end
