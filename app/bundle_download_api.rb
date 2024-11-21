module FilesMockServer
  class BundleDownloadAPI < Grape::API
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
      optional :bundle_id, type: Integer
      optional :bundle_registration_id, type: Integer
    end
    get "/api/rest/v1/bundle_downloads" do
      status 200
      [ { "bundle_registration" => { "code" => "abc123", "name" => "account", "company" => "Action Verb", "email" => "john.doe@files.com", "ip" => "10.1.1.1", "inbox_code" => "abc123", "clickwrap_body" => "example", "form_field_set_id" => 1, "form_field_data" => { "key" => "example value" }, "bundle_code" => "example", "bundle_id" => 1, "bundle_recipient_id" => 1, "created_at" => "2000-01-01T01:00:00Z" }, "download_method" => "file", "path" => "a/b/test.txt", "created_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :bundle_id, type: Integer
      optional :bundle_registration_id, type: Integer
    end
    post "/api/rest/v1/bundle_downloads/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
