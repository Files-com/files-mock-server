module FilesMockServer
  class PaymentAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/payments" do
      status 200
      [ { "id" => 1, "amount" => 1.0, "balance" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "description" => "Service from 2019-01-01 through 2019-12-31", "type" => "invoice", "service_end_at" => "2000-01-01T01:00:00Z", "service_start_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "plan" => "Enterprise", "site" => "My site" }, "method" => "paypal", "payment_line_items" => { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "invoice_id" => 1, "payment_id" => 1, "updated_at" => "2000-01-01T01:00:00Z" }, "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "", "site_name" => "My Site", "type" => "invoice", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/payments/:id" do
      status 200
      { "id" => 1, "amount" => 1.0, "balance" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "description" => "Service from 2019-01-01 through 2019-12-31", "type" => "invoice", "service_end_at" => "2000-01-01T01:00:00Z", "service_start_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z", "plan" => "Enterprise", "site" => "My site" }, "method" => "paypal", "payment_line_items" => { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "invoice_id" => 1, "payment_id" => 1, "updated_at" => "2000-01-01T01:00:00Z" }, "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "", "site_name" => "My Site", "type" => "invoice", "updated_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
