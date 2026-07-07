module FilesMockServer
  class SupportRequestAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/support_requests" do
      status 200
      [ { "id" => 1, "subject" => "example", "comment" => "example", "created_at" => "2000-01-01T01:00:00Z", "access_until" => "2000-01-01T01:00:00Z", "customer_success_access" => "`no`", "priority" => "`low`", "name" => "John Doe", "phone_number" => "555-555-5555" } ]
    end

    params do
      optional :customer_success_access, type: String
      optional :access_reset, type: Boolean
      requires :email, type: String
      requires :subject, type: String
      requires :comment, type: String
      optional :priority, type: String
      optional :phone_number, type: String
      optional :name, type: String
      optional :attachments_files, type: [ File ]
    end
    post "/api/rest/v1/support_requests" do
      status 201
      { "id" => 1, "subject" => "example", "comment" => "example", "created_at" => "2000-01-01T01:00:00Z", "access_until" => "2000-01-01T01:00:00Z", "customer_success_access" => "`no`", "priority" => "`low`", "name" => "John Doe", "phone_number" => "555-555-5555" }
    end

    params do
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/support_requests/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end

    params do
      requires :id, type: Integer
      optional :customer_success_access, type: String
      optional :access_reset, type: Boolean
    end
    patch "/api/rest/v1/support_requests/:id" do
      status 200
      { "id" => 1, "subject" => "example", "comment" => "example", "created_at" => "2000-01-01T01:00:00Z", "access_until" => "2000-01-01T01:00:00Z", "customer_success_access" => "`no`", "priority" => "`low`", "name" => "John Doe", "phone_number" => "555-555-5555" }
    end
  end
end
