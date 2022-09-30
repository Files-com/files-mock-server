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
      [ { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
    end

    params do
      optional :user_id, type: Integer
      optional :title, type: String
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :skip_company, type: Boolean
      optional :form_fields, type: Array[Hash]
    end
    post "/api/rest/v1/form_field_sets" do
      status 201
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
    end

    params do
      requires :id, type: Integer
      optional :title, type: String
      optional :skip_email, type: Boolean
      optional :skip_name, type: Boolean
      optional :skip_company, type: Boolean
      optional :form_fields, type: Array[Hash]
    end
    patch "/api/rest/v1/form_field_sets/:id" do
      status 200
      { "id" => 1, "title" => "Sample Form Title", "form_layout" => [ 1, 2, 3, 4 ], "form_fields" => [ nil ], "skip_name" => true, "skip_email" => true, "skip_company" => true }
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
