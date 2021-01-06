module FilesMockServer
  class BundleRecipientAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      requires :bundle_id, type: Integer
    end
    get "/api/rest/v1/bundle_recipients" do
      status 200
      [ { "company" => "Acme Inc.", "name" => "John Doe", "note" => "Some note.", "recipient" => "john.doe@example.com", "sent_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
