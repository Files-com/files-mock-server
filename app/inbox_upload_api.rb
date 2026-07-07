module FilesMockServer
  class InboxUploadAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/inbox_uploads" do
      status 200
      [ { "inbox_registration" => { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "inbox_id" => 1, "inbox_recipient_id" => 1, "inbox_title" => "example", "created_at" => "2000-01-01T01:00:00Z" }, "path" => "a/b/test.txt", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
