module FilesMockServer
  class AppAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/apps" do
      status 200
      [ { "name" => "", "extended_description" => "", "documentation_links" => "Important Info => http://files.test/learn-more", "icon_url" => "", "logo_url" => "", "screenshot_list_urls" => [ "" ], "logo_thumbnail_url" => "", "sso_strategy_type" => "", "remote_server_type" => "", "folder_behavior_type" => "", "external_homepage_url" => "", "app_type" => "", "featured" => true } ]
    end
  end
end
