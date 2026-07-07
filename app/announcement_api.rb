module FilesMockServer
  class AnnouncementAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
    end
    get "/api/rest/v1/announcements" do
      status 200
      [ { "id" => 1, "headline" => "Files.com Now Supports In-App Announcements!", "body" => "This is the body.", "button_text" => "View Blog Post", "button_url" => "https://www.files.com/blog/", "html_body" => "<p>This is the HTML version of the body.</p>", "label" => "New Feature", "label_color" => "#000000", "publish_at" => "2000-01-01T01:00:00Z", "slug" => "new-feature" } ]
    end

    params do
      optional :sort_by, type: Hash
    end
    post "/api/rest/v1/announcements/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
