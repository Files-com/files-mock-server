module FilesMockServer
  class LeadAPI < Grape::API
    format :json

    params do
      optional :recaptcha_token, type: String
      optional :name, type: String
      optional :address, type: String
      optional :address_2, type: String
      optional :city, type: String
      optional :contact_name, type: String
      optional :currency, type: String
      optional :email, type: String
      optional :language, type: String
      optional :phone_number, type: String
      optional :state, type: String
      optional :zip, type: String
      optional :form_name, type: String
      optional :lead_source, type: String
      optional :opportunity_comment, type: String
      optional :opportunity_type, type: String
      optional :gclid, type: String
      optional :original_brand, type: String
      optional :utm_campaign, type: String
      optional :utm_content, type: String
      optional :utm_domain, type: String
      optional :utm_medium, type: String
      optional :utm_source, type: String
      optional :utm_term, type: String
      optional :time_zone, type: String
      optional :time_zone_offset, type: Integer
    end
    post "/api/rest/v1/leads" do
      status 201
      { "id" => 1, "code" => "abc123", "name" => "account", "address" => "123 Main St", "address_2" => "Window 1", "city" => "New York", "company_name" => "Action Verb", "contact_name" => "John Doe", "country" => "US", "currency" => "USD", "email" => "john.doe@files.com", "language" => "en", "phone_number" => "555-555-5555", "state" => "NY", "zip" => "00000", "lead_level" => "mql", "signup_page_split_test_group" => "control" }
    end

    params do
      requires :code, type: String
      optional :recaptcha_token, type: String
      optional :name, type: String
      optional :address, type: String
      optional :address_2, type: String
      optional :city, type: String
      optional :contact_name, type: String
      optional :currency, type: String
      optional :email, type: String
      optional :language, type: String
      optional :phone_number, type: String
      optional :state, type: String
      optional :zip, type: String
      optional :form_name, type: String
      optional :lead_source, type: String
      optional :opportunity_comment, type: String
      optional :opportunity_type, type: String
      optional :gclid, type: String
      optional :original_brand, type: String
      optional :utm_campaign, type: String
      optional :utm_content, type: String
      optional :utm_domain, type: String
      optional :utm_medium, type: String
      optional :utm_source, type: String
      optional :utm_term, type: String
      optional :time_zone, type: String
      optional :time_zone_offset, type: Integer
    end
    patch "/api/rest/v1/leads/:code" do
      status 200
      { "id" => 1, "code" => "abc123", "name" => "account", "address" => "123 Main St", "address_2" => "Window 1", "city" => "New York", "company_name" => "Action Verb", "contact_name" => "John Doe", "country" => "US", "currency" => "USD", "email" => "john.doe@files.com", "language" => "en", "phone_number" => "555-555-5555", "state" => "NY", "zip" => "00000", "lead_level" => "mql", "signup_page_split_test_group" => "control" }
    end
  end
end
