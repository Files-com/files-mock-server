module FilesMockServer
  class EmailLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/email_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "message" => "example", "status" => "example", "subject" => "example", "to" => "example", "cc" => "example", "delivery_method" => "example", "smtp_hostname" => "example", "smtp_ip" => "example" } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    post "/api/rest/v1/email_logs/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
