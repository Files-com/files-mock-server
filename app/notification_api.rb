module FilesMockServer
  class NotificationAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
      optional :filter_prefix, type: Hash
      optional :path, type: String
      optional :include_ancestors, type: Boolean
      optional :group_id, type: String
    end
    get "/api/rest/v1/notifications" do
      status 200
      [ { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "example", "triggering_group_ids" => [ 1 ], "triggering_user_ids" => [ 1 ], "trigger_by_share_recipients" => true, "notify_user_actions" => true, "notify_on_copy" => true, "notify_on_delete" => true, "notify_on_download" => true, "notify_on_move" => true, "notify_on_upload" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "message" => "custom notification email message", "triggering_filenames" => [ "*.jpg", "notify_file.txt" ], "unsubscribed" => true, "unsubscribed_reason" => "example", "user_id" => 1, "username" => "User", "suppressed_email" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/notifications/:id" do
      status 200
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "example", "triggering_group_ids" => [ 1 ], "triggering_user_ids" => [ 1 ], "trigger_by_share_recipients" => true, "notify_user_actions" => true, "notify_on_copy" => true, "notify_on_delete" => true, "notify_on_download" => true, "notify_on_move" => true, "notify_on_upload" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "message" => "custom notification email message", "triggering_filenames" => [ "*.jpg", "notify_file.txt" ], "unsubscribed" => true, "unsubscribed_reason" => "example", "user_id" => 1, "username" => "User", "suppressed_email" => true }
    end

    params do
      optional :user_id, type: Integer
      optional :notify_on_copy, type: Boolean
      optional :notify_on_delete, type: Boolean
      optional :notify_on_download, type: Boolean
      optional :notify_on_move, type: Boolean
      optional :notify_on_upload, type: Boolean
      optional :notify_user_actions, type: Boolean
      optional :recursive, type: Boolean
      optional :send_interval, type: String
      optional :message, type: String
      optional :triggering_filenames, type: [ String ]
      optional :triggering_group_ids, type: [ Integer ]
      optional :triggering_user_ids, type: [ Integer ]
      optional :trigger_by_share_recipients, type: Boolean
      optional :group_id, type: Integer
      optional :path, type: String
      optional :username, type: String
    end
    post "/api/rest/v1/notifications" do
      status 201
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "example", "triggering_group_ids" => [ 1 ], "triggering_user_ids" => [ 1 ], "trigger_by_share_recipients" => true, "notify_user_actions" => true, "notify_on_copy" => true, "notify_on_delete" => true, "notify_on_download" => true, "notify_on_move" => true, "notify_on_upload" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "message" => "custom notification email message", "triggering_filenames" => [ "*.jpg", "notify_file.txt" ], "unsubscribed" => true, "unsubscribed_reason" => "example", "user_id" => 1, "username" => "User", "suppressed_email" => true }
    end

    params do
      requires :id, type: Integer
      optional :notify_on_copy, type: Boolean
      optional :notify_on_delete, type: Boolean
      optional :notify_on_download, type: Boolean
      optional :notify_on_move, type: Boolean
      optional :notify_on_upload, type: Boolean
      optional :notify_user_actions, type: Boolean
      optional :recursive, type: Boolean
      optional :send_interval, type: String
      optional :message, type: String
      optional :triggering_filenames, type: [ String ]
      optional :triggering_group_ids, type: [ Integer ]
      optional :triggering_user_ids, type: [ Integer ]
      optional :trigger_by_share_recipients, type: Boolean
    end
    patch "/api/rest/v1/notifications/:id" do
      status 200
      { "id" => 1, "path" => "", "group_id" => 1, "group_name" => "example", "triggering_group_ids" => [ 1 ], "triggering_user_ids" => [ 1 ], "trigger_by_share_recipients" => true, "notify_user_actions" => true, "notify_on_copy" => true, "notify_on_delete" => true, "notify_on_download" => true, "notify_on_move" => true, "notify_on_upload" => true, "recursive" => true, "send_interval" => "fifteen_minutes", "message" => "custom notification email message", "triggering_filenames" => [ "*.jpg", "notify_file.txt" ], "unsubscribed" => true, "unsubscribed_reason" => "example", "user_id" => 1, "username" => "User", "suppressed_email" => true }
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
