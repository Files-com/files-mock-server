module FilesMockServer
  class IpAddressAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses" do
      status 200
      [ { "id" => "Site", "associated_with" => "Site", "group_id" => 1, "ip_addresses" => [ "127.0.0.1" ] } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses/smartfile-reserved" do
      status 200
      [ { "ip_address" => "1.1.1.1", "server_name" => "server-1", "ftp_enabled" => true, "sftp_enabled" => true } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses/exavault-reserved" do
      status 200
      [ { "ip_address" => "1.1.1.1", "server_name" => "server-1", "ftp_enabled" => true, "sftp_enabled" => true } ]
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/ip_addresses/reserved" do
      status 200
      [ { "ip_address" => "1.1.1.1", "server_name" => "server-1", "ftp_enabled" => true, "sftp_enabled" => true } ]
    end

    post "/api/rest/v1/ip_addresses/smartfile-reserved/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    post "/api/rest/v1/ip_addresses/exavault-reserved/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    post "/api/rest/v1/ip_addresses/reserved/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    post "/api/rest/v1/ip_addresses/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
