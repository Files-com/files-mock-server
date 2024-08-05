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
      [ { "app_type" => "example", "documentation_links" => { "Important Info" => "http://files.test/learn-more" }, "extended_description" => "example", "extended_description_for_marketing_site" => "example", "external_homepage_url" => "example", "featured" => true, "folder_behavior_type" => "example", "icon_url" => "example", "logo_thumbnail_url" => "example", "logo_url" => "example", "marketing_intro" => "example", "marketing_youtube_url" => "example", "name" => "example", "package_manager_install_command" => "example", "remote_server_type" => "example", "screenshot_list_urls" => [ "example" ], "sdk_installation_instructions_link" => "example", "short_description" => "example", "sso_strategy_type" => "example", "tutorial_youtube_url" => "example" } ]
    end
  end
end
