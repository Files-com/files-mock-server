module FilesMockServer
  class DnsRecordAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/dns_records" do
      status 200
      [ { "id" => "example", "domain" => "my-custom-domain.com", "rrtype" => "CNAME", "value" => "mysite.files.com" } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    post "/api/rest/v1/dns_records/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
