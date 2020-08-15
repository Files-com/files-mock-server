module FilesMockServer
  class ExternalEventAPI < Grape::API
    format :json

    params do
      optional :page, type: Integer
      optional :per_page, type: Integer
      optional :action, type: String
      optional :cursor, type: String
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
    end
    get "/api/rest/v1/external_events" do
      status 200
      [ { "event_type" => "", "status" => "", "body" => "", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
