module FilesMockServer
  class BundleNotificationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/bundle_notifications" do
      status 200
      [ { "bundle_id" => 1, "id" => 1, "notify_on_registration" => true, "notify_on_upload" => true, "user_id" => 1 } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/bundle_notifications/:id" do
      status 200
      { "bundle_id" => 1, "id" => 1, "notify_on_registration" => true, "notify_on_upload" => true, "user_id" => 1 }
    end

    params do
      requires :bundle_id, type: Integer
      optional :user_id, type: Integer
      optional :notify_on_registration, type: Boolean
      optional :notify_on_upload, type: Boolean
    end
    post "/api/rest/v1/bundle_notifications" do
      status 201
      { "bundle_id" => 1, "id" => 1, "notify_on_registration" => true, "notify_on_upload" => true, "user_id" => 1 }
    end

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    post "/api/rest/v1/bundle_notifications/create_export" do
      status 201
      [ { "id" => 1, "export_status" => "example", "export_type" => "example", "export_rows" => 1, "download_uri" => "example", "message" => "example" } ]
    end

    params do
      requires :id, type: Integer
      optional :notify_on_registration, type: Boolean
      optional :notify_on_upload, type: Boolean
    end
    patch "/api/rest/v1/bundle_notifications/:id" do
      status 200
      { "bundle_id" => 1, "id" => 1, "notify_on_registration" => true, "notify_on_upload" => true, "user_id" => 1 }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/bundle_notifications/:id" do
      status 204
      body false
    end
  end
end
