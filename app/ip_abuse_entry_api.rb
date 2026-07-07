module FilesMockServer
  class IpAbuseEntryAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_abuse_entries" do
      status 200
      body false
    end

    params do
      requires :ip, type: String
      optional :list, type: String
      optional :hostname, type: String
      optional :reason, type: String
    end
    post "/api/rest/v1/ip_abuse_entries" do
      status 201
      body false
    end

    post "/api/rest/v1/ip_abuse_entries/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
