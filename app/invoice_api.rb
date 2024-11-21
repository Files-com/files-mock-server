module FilesMockServer
  class InvoiceAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/invoices" do
      status 200
      [ { "id" => 1, "amount" => 1.0, "balance" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => [ { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "description" => "Service from 2019-01-01 through 2019-12-31", "type" => "invoice", "service_end_at" => "2000-01-01T01:00:00Z", "service_start_at" => "2000-01-01T01:00:00Z", "plan" => "Premier", "site" => "My site" } ], "method" => "paypal", "payment_line_items" => [ { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "invoice_id" => 1, "payment_id" => 1 } ], "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "example", "site_name" => "My Site", "type" => "invoice" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/invoices/:id" do
      status 200
      { "id" => 1, "amount" => 1.0, "balance" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => [ { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "description" => "Service from 2019-01-01 through 2019-12-31", "type" => "invoice", "service_end_at" => "2000-01-01T01:00:00Z", "service_start_at" => "2000-01-01T01:00:00Z", "plan" => "Premier", "site" => "My site" } ], "method" => "paypal", "payment_line_items" => [ { "amount" => 1.0, "created_at" => "2000-01-01T01:00:00Z", "invoice_id" => 1, "payment_id" => 1 } ], "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "example", "site_name" => "My Site", "type" => "invoice" }
    end

    post "/api/rest/v1/invoices/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end
  end
end
