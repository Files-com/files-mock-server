module FilesMockServer
  class PublicUrlAPI < Grape::API
    format :json

    params do
      requires :hostname, type: String
      requires :path, type: String
    end
    post "/api/rest/v1/public_urls" do
      status 201
      { "http-code" => 1, "type" => "not-found/file-not-found", "http_headers" => "example", "body" => "example", "download_uri" => "example", "internal_download_uri" => "example", "redirect" => "example", "mime_type" => "example", "site_id" => 1, "remote_server_id" => 1, "headers" => { "key" => "example value" }, "socks_ips" => [ "example" ], "true_path" => "example", "cache_for_seconds" => 1 }
    end
  end
end
