module FilesMockServer
  class InboxUploadAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :inbox_registration_id, type: Integer
      optional :inbox_id, type: Integer
    end
    get "/api/rest/v1/inbox_uploads" do
      status 200
      [ { "inbox_registration" => "", "path" => "a/b/test.txt", "created_at" => "2020-01-01 00:00:00" } ]
    end
  end
end
