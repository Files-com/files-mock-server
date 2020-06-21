module FilesMockServer
  class InvoiceAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
    end
    get "/invoices" do
      status 200
      [ { "id" => 1, "amount" => "", "balance" => "", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => [], "method" => "paypal", "payment_line_items" => [], "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "", "site_name" => "My Site", "type" => "invoice", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/invoices/:id" do
      status 200
      { "id" => 1, "amount" => "", "balance" => "", "created_at" => "2000-01-01T01:00:00Z", "currency" => "USD", "download_uri" => "https://url...", "invoice_line_items" => [], "method" => "paypal", "payment_line_items" => [], "payment_reversed_at" => "2000-01-01T01:00:00Z", "payment_type" => "", "site_name" => "My Site", "type" => "invoice", "updated_at" => "2000-01-01T01:00:00Z" }
    end
  end
end
