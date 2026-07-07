module FilesMockServer
  class PublicInboxAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/public_inboxes" do
      status 200
      [ { "color_left" => "#0066a7", "color_link" => "#d34f5d", "color_text" => "#0066a7", "color_top" => "#000000", "color_top_text" => "#ffffff", "title" => "example", "description" => "My inbox", "help_text" => "If you need any help submitting your application, please call our front desk.", "key" => "application-form", "show_on_login_page" => true, "has_password" => true, "require_registration" => true, "dont_allow_folders_in_uploads" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true, "in_use" => true }, "require_logout" => true, "logo" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "logo_click_href" => "https://www.example.com", "thumbnail" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" } } ]
    end

    params do
      requires :key, type: String
      optional :recipient_code, type: String
    end
    get "/api/rest/v1/public_inboxes/key/:key" do
      status 200
      { "color_left" => "#0066a7", "color_link" => "#d34f5d", "color_text" => "#0066a7", "color_top" => "#000000", "color_top_text" => "#ffffff", "title" => "example", "description" => "My inbox", "help_text" => "If you need any help submitting your application, please call our front desk.", "key" => "application-form", "show_on_login_page" => true, "has_password" => true, "require_registration" => true, "dont_allow_folders_in_uploads" => true, "clickwrap_body" => "[Legal text]", "form_field_set" => { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true, "in_use" => true }, "require_logout" => true, "logo" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" }, "logo_click_href" => "https://www.example.com", "thumbnail" => { "name" => "My logo", "uri" => "https://mysite.files.com/.../my_image.png" } }
    end

    post "/api/rest/v1/public_inboxes/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
