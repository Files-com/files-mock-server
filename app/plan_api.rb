module FilesMockServer
  class PlanAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :currency, type: String
    end
    get "/api/rest/v1/plans" do
      status 200
      [ { "id" => 1, "activation_cost" => "10.0", "addon_description" => "FTP/SFTP/WebDAV addon", "annually" => "2988.0", "annually_addon" => "2988.0", "automation_and_sync_flow_overage_cost" => "25.0", "automation_and_sync_flows" => 2, "child_sites" => 1, "currency" => "USD", "dedicated_ip" => true, "dedicated_ips" => 1, "domain_count" => 1, "feature_bundle_eca" => true, "feature_bundle_power" => true, "feature_bundle_premier" => true, "feature_bundle_starter" => true, "monthly" => "249.0", "monthly_addon" => "249.0", "name" => "Power", "outbound_connections" => 1, "preview_page_limit" => 100, "regions_included" => 2, "remote_sync_interval" => 1, "signup_page_marketing_text" => "example", "system_users" => 1, "staging_sites" => 1, "transformation_and_ai_credit_overage_cost_per_million" => "0.1", "transformation_and_ai_credits" => 1, "trial_days" => 30, "user_cost" => "5.0", "usage_cost" => "0.1", "usage_included" => 1, "users" => 1 } ]
    end

    params do
      optional :currency, type: String
    end
    post "/api/rest/v1/plans/create_export" do
      status 201
      { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" }
    end
  end
end
