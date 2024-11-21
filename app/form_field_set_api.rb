module FilesMockServer
  class FormFieldSetAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/form_field_sets" do
      status 200
      [ { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
    end

    params do
      optional :user_id, type: Integer
      optional :title, type: String
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :skip_company, type: Boolean
      optional :form_fields, type: [ Hash ]
    end
    post "/api/rest/v1/form_field_sets" do
      status 201
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
    end

    params do
      optional :user_id, type: Integer
    end
    post "/api/rest/v1/form_field_sets/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
      optional :title, type: String
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :skip_company, type: Boolean
      optional :form_fields, type: [ Hash ]
    end
    patch "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/form_field_sets/:id" do
      status 204
      body false
    end
  end
end
