module FilesMockServer
  class DnsRecordAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api/rest/v1/dns_records" do
      status 200
      [ { "id" => "customdomain.com-CNAME-site.files.com", "domain" => "my-custom-domain.com", "rrtype" => "CNAME", "value" => "mysite.files.com" } ]
    end
  end
end
