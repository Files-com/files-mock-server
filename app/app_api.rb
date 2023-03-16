module FilesMockServer
  class AppAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
    end
    get "/api/rest/v1/apps" do
      status 200
      [ { "name" => "example", "extended_description" => "example", "short_description" => "example", "documentation_links" => { "Important Info" => "http://files.test/learn-more" }, "icon_url" => "example", "logo_url" => "example", "screenshot_list_urls" => [ "example" ], "logo_thumbnail_url" => "example", "sso_strategy_type" => "example", "remote_server_type" => "example", "folder_behavior_type" => "example", "external_homepage_url" => "example", "marketing_youtube_url" => "example", "tutorial_youtube_url" => "example", "app_type" => "example", "featured" => true } ]
    end
  end
end
