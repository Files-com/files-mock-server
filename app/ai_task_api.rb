module FilesMockServer
  class AiTaskAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/ai_tasks" do
      status 200
      [ { "id" => 1, "workspace_id" => 1, "name" => "Summarize daily reports", "description" => "Summarizes files uploaded by the accounting team.", "prompt" => "Summarize the uploaded file and identify follow-up actions.", "permission_set" => "files_only", "path" => "incoming/reports", "source" => "*.pdf", "disabled" => true, "trigger" => "daily", "trigger_actions" => [ "create" ], "interval" => "day", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every day at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "master_admin_user_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :holiday_region, type: String
      optional :interval, type: String
      requires :name, type: String
      optional :path, type: String
      optional :permission_set, type: String
      requires :prompt, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_time_zone, type: String
      optional :schedule_times_of_day, type: [ String ]
      optional :source, type: String
      optional :trigger, type: String
      optional :trigger_actions, type: [ String ]
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/ai_tasks" do
      status 201
      { "id" => 1, "workspace_id" => 1, "name" => "Summarize daily reports", "description" => "Summarizes files uploaded by the accounting team.", "prompt" => "Summarize the uploaded file and identify follow-up actions.", "permission_set" => "files_only", "path" => "incoming/reports", "source" => "*.pdf", "disabled" => true, "trigger" => "daily", "trigger_actions" => [ "create" ], "interval" => "day", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every day at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "master_admin_user_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/ai_tasks/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Summarize daily reports", "description" => "Summarizes files uploaded by the accounting team.", "prompt" => "Summarize the uploaded file and identify follow-up actions.", "permission_set" => "files_only", "path" => "incoming/reports", "source" => "*.pdf", "disabled" => true, "trigger" => "daily", "trigger_actions" => [ "create" ], "interval" => "day", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every day at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "master_admin_user_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :description, type: String
      optional :disabled, type: Boolean
      optional :holiday_region, type: String
      optional :interval, type: String
      optional :name, type: String
      optional :path, type: String
      optional :permission_set, type: String
      optional :prompt, type: String
      optional :recurring_day, type: Integer
      optional :schedule_days_of_week, type: [ Integer ]
      optional :schedule_time_zone, type: String
      optional :schedule_times_of_day, type: [ String ]
      optional :source, type: String
      optional :trigger, type: String
      optional :trigger_actions, type: [ String ]
      optional :workspace_id, type: Integer
    end
    patch "/api/rest/v1/ai_tasks/:id" do
      status 200
      { "id" => 1, "workspace_id" => 1, "name" => "Summarize daily reports", "description" => "Summarizes files uploaded by the accounting team.", "prompt" => "Summarize the uploaded file and identify follow-up actions.", "permission_set" => "files_only", "path" => "incoming/reports", "source" => "*.pdf", "disabled" => true, "trigger" => "daily", "trigger_actions" => [ "create" ], "interval" => "day", "recurring_day" => 1, "schedule_days_of_week" => [ 1, 3, 5 ], "schedule_times_of_day" => [ "06:30" ], "schedule_time_zone" => "Eastern Time (US & Canada)", "holiday_region" => "us", "human_readable_schedule" => "Runs every day at 06:30 AM UTC TZ.", "last_run_at" => "2000-01-01T01:00:00Z", "master_admin_user_id" => 1, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/ai_tasks/:id" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/ai_tasks/:id/manual_run" do
      status 204
      body false
    end
  end
end
