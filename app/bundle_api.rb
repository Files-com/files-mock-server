module FilesMockServer
  class BundleAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/bundles" do
      status 200
      [ { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "expires_at" => "2000-01-01T01:00:00Z", "password_protected" => true, "permissions" => "read", "preview_only" => true, "require_registration" => true, "require_share_recipient" => true, "require_logout" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }, "skip_name" => true, "skip_email" => true, "skip_company" => true, "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "dont_separate_submissions_by_folder" => true, "max_uses" => 1, "note" => "The internal note on the bundle.", "path_template" => "{{name}}_{{ip}}", "send_email_receipt_to_uploader" => true, "snapshot_id" => 1, "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "watermark_attachment" => nil, "watermark_value" => { "key" => "example value" }, "has_inbox" => true, "paths" => [ "file.txt" ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "expires_at" => "2000-01-01T01:00:00Z", "password_protected" => true, "permissions" => "read", "preview_only" => true, "require_registration" => true, "require_share_recipient" => true, "require_logout" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }, "skip_name" => true, "skip_email" => true, "skip_company" => true, "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "dont_separate_submissions_by_folder" => true, "max_uses" => 1, "note" => "The internal note on the bundle.", "path_template" => "{{name}}_{{ip}}", "send_email_receipt_to_uploader" => true, "snapshot_id" => 1, "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "watermark_attachment" => nil, "watermark_value" => { "key" => "example value" }, "has_inbox" => true, "paths" => [ "file.txt" ] }
    end

    params do
      optional :user_id, type: Integer
      requires :paths, type: Array[String]
      optional :password, type: String
      optional :form_field_set_id, type: Integer
      optional :create_snapshot, type: Boolean
      optional :dont_separate_submissions_by_folder, type: Boolean
      optional :expires_at, type: String
      optional :finalize_snapshot, type: Boolean
      optional :max_uses, type: Integer
      optional :description, type: String
      optional :note, type: String
      optional :code, type: String
      optional :path_template, type: String
      optional :permissions, type: String
      optional :preview_only, type: Boolean
      optional :require_registration, type: Boolean
      optional :clickwrap_id, type: Integer
      optional :inbox_id, type: Integer
      optional :require_share_recipient, type: Boolean
      optional :send_email_receipt_to_uploader, type: Boolean
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :skip_company, type: Boolean
      optional :snapshot_id, type: Integer
      optional :watermark_attachment_file, type: File
    end
    post "/api/rest/v1/bundles" do
      status 201
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "expires_at" => "2000-01-01T01:00:00Z", "password_protected" => true, "permissions" => "read", "preview_only" => true, "require_registration" => true, "require_share_recipient" => true, "require_logout" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }, "skip_name" => true, "skip_email" => true, "skip_company" => true, "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "dont_separate_submissions_by_folder" => true, "max_uses" => 1, "note" => "The internal note on the bundle.", "path_template" => "{{name}}_{{ip}}", "send_email_receipt_to_uploader" => true, "snapshot_id" => 1, "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "watermark_attachment" => nil, "watermark_value" => { "key" => "example value" }, "has_inbox" => true, "paths" => [ "file.txt" ] }
    end

    params do
      requires :id, type: Integer
      optional :to, type: Array[String]
      optional :note, type: String
      optional :recipients, type: Array[Hash]
    end
    post "/api/rest/v1/bundles/:id/share" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      optional :paths, type: Array[String]
      optional :password, type: String
      optional :form_field_set_id, type: Integer
      optional :clickwrap_id, type: Integer
      optional :code, type: String
      optional :create_snapshot, type: Boolean
      optional :description, type: String
      optional :dont_separate_submissions_by_folder, type: Boolean
      optional :expires_at, type: String
      optional :finalize_snapshot, type: Boolean
      optional :inbox_id, type: Integer
      optional :max_uses, type: Integer
      optional :note, type: String
      optional :path_template, type: String
      optional :permissions, type: String
      optional :preview_only, type: Boolean
      optional :require_registration, type: Boolean
      optional :require_share_recipient, type: Boolean
      optional :send_email_receipt_to_uploader, type: Boolean
      optional :skip_company, type: Boolean
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :watermark_attachment_delete, type: Boolean
      optional :watermark_attachment_file, type: File
    end
    patch "/api/rest/v1/bundles/:id" do
      status 200
      { "code" => "abc123", "url" => "https://subdomain.files.com/f/12345678", "description" => "The public description of the bundle.", "expires_at" => "2000-01-01T01:00:00Z", "password_protected" => true, "permissions" => "read", "preview_only" => true, "require_registration" => true, "require_share_recipient" => true, "require_logout" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }, "skip_name" => true, "skip_email" => true, "skip_company" => true, "id" => 1, "created_at" => "2000-01-01T01:00:00Z", "dont_separate_submissions_by_folder" => true, "max_uses" => 1, "note" => "The internal note on the bundle.", "path_template" => "{{name}}_{{ip}}", "send_email_receipt_to_uploader" => true, "snapshot_id" => 1, "user_id" => 1, "username" => "user", "clickwrap_id" => 1, "inbox_id" => 1, "watermark_attachment" => nil, "watermark_value" => { "key" => "example value" }, "has_inbox" => true, "paths" => [ "file.txt" ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/bundles/:id" do
      status 204
      body false
    end
  end
end
