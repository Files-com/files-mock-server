module FilesMockServer
  class InboxUploadAPI < Grape::API
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
      optional :inbox_registration_id, type: Integer
      optional :inbox_id, type: Integer
    end
    get "/api/rest/v1/inbox_uploads" do
      status 200
      [ { "inbox_registration" => "example", "path" => "a/b/test.txt", "created_at" => "2000-01-01T01:00:00Z" } ]
    end
  end
end
