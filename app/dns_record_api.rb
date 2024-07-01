module FilesMockServer
  class DnsRecordAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :action, type: String
      optional :page, type: Integer
    end
    get "/api/rest/v1/dns_records" do
      status 200
      [ { "id" => "example", "domain" => "my-custom-domain.com", "rrtype" => "CNAME", "value" => "mysite.files.com" } ]
    end
  end
end
