module FilesMockServer
  class AppAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/api/rest/v1/apps" do
      status 200
      [ { "name" => "", "extended_description" => "", "documentation_links" => "Important Info => http://files.test/learn-more", "sso_strategy_type" => "", "remote_server_type" => "", "folder_behavior_type" => "", "external_homepage_url" => "", "app_type" => "", "featured" => true } ]
    end
  end
end
