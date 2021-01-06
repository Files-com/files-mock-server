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
      [ { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] }
    end

    params do
      optional :user_id, type: Integer
      optional :title, type: String
      optional :form_fields, type: Array[Hash]
    end
    post "/api/rest/v1/form_field_sets" do
      status 201
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] }
    end

    params do
      requires :id, type: Integer
      optional :title, type: String
      optional :form_fields, type: Array[Hash]
    end
    patch "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ { "id" => 1, "label" => "Sample Label", "required" => true, "help_text" => "Help Text", "field_type" => "text", "options_for_select" => [ "red", "green", "blue" ], "default_option" => "red", "form_field_set_id" => 1 } ] }
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
