module FilesMockServer
  class InboxRecipientAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      requires :inbox_id, type: Integer
    end
    get "/api/rest/v1/inbox_recipients" do
      status 200
      [ { "company" => "Acme Inc.", "name" => "John Doe", "note" => "Some note.", "recipient" => "john.doe@example.com", "sent_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :inbox_id, type: Integer
      requires :recipient, type: String
      optional :name, type: String
      optional :company, type: String
      optional :note, type: String
      optional :share_after_create, type: Boolean
    end
    post "/api/rest/v1/inbox_recipients" do
      status 201
      { "company" => "Acme Inc.", "name" => "John Doe", "note" => "Some note.", "recipient" => "john.doe@example.com", "sent_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      requires :inbox_id, type: Integer
    end
    post "/api/rest/v1/inbox_recipients/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
