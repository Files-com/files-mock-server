module FilesMockServer
  class EmailLogAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/email_logs" do
      status 200
      [ { "timestamp" => "2000-01-01T01:00:00Z", "message" => "example", "status" => "example", "subject" => "example", "to" => "example", "cc" => "example", "delivery_method" => "example", "smtp_hostname" => "example", "smtp_ip" => "example" } ]
    end
  end
end
