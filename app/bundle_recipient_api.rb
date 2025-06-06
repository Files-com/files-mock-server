module FilesMockServer
  class BundleRecipientAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      requires :bundle_id, type: Integer
    end
    get "/api/rest/v1/bundle_recipients" do
      status 200
      [ { "company" => "Acme Inc.", "name" => "John Doe", "note" => "Some note.", "recipient" => "john.doe@example.com", "sent_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :user_id, type: Integer
      requires :bundle_id, type: Integer
      requires :recipient, type: String
      optional :name, type: String
      optional :company, type: String
      optional :note, type: String
      optional :share_after_create, type: Boolean
    end
    post "/api/rest/v1/bundle_recipients" do
      status 201
      { "company" => "Acme Inc.", "name" => "John Doe", "note" => "Some note.", "recipient" => "john.doe@example.com", "sent_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
