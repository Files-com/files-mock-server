module FilesMockServer
  class NotificationAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_gt, type: Hash
      optional :filter_gteq, type: Hash
      optional :filter_like, type: Hash
      optional :filter_lt, type: Hash
      optional :filter_lteq, type: Hash
      optional :group_id, type: Integer
      optional :path, type: String
      optional :include_ancestors, type: Boolean
    end
    get "/api/rest/v1/notifications" do
      status 200
      [ { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "", "notify_user_actions" => true, "notify_on_copy" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "unsubscribed" => true, "unsubscribed_reason" => "", "user_id" => 1, "username" => "User", "suppressed_email" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/notifications/:id" do
      status 200
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "", "notify_user_actions" => true, "notify_on_copy" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "unsubscribed" => true, "unsubscribed_reason" => "", "user_id" => 1, "username" => "User", "suppressed_email" => true }
    end

    params do
      optional :user_id, type: Integer
      optional :notify_on_copy, type: Boolean
      optional :notify_user_actions, type: Boolean
      optional :recursive, type: Boolean
      optional :send_interval, type: String
      optional :group_id, type: Integer
      optional :path, type: String
      optional :username, type: String
    end
    post "/api/rest/v1/notifications" do
      status 201
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "", "notify_user_actions" => true, "notify_on_copy" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "unsubscribed" => true, "unsubscribed_reason" => "", "user_id" => 1, "username" => "User", "suppressed_email" => true }
    end

    params do
      requires :id, type: Integer
      optional :notify_on_copy, type: Boolean
      optional :notify_user_actions, type: Boolean
      optional :recursive, type: Boolean
      optional :send_interval, type: String
    end
    patch "/api/rest/v1/notifications/:id" do
      status 200
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "", "notify_user_actions" => true, "notify_on_copy" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "unsubscribed" => true, "unsubscribed_reason" => "", "user_id" => 1, "username" => "User", "suppressed_email" => true }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/notifications/:id" do
      status 204
      body false
    end
  end
end
