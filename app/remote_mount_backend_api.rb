module FilesMockServer
  class RemoteMountBackendAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/remote_mount_backends" do
      status 200
      [ { "canary_file_path" => "backend1.txt", "enabled" => true, "fall" => 1, "health_check_enabled" => true, "health_check_type" => "active", "interval" => 60, "min_free_cpu" => 1.0, "min_free_mem" => 1.0, "priority" => 1, "remote_path" => "/path/on/remote", "remote_server_id" => 1, "remote_server_mount_id" => 1, "rise" => 1, "status" => "healthy", "undergoing_maintenance" => true } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/remote_mount_backends/:id" do
      status 200
      { "canary_file_path" => "backend1.txt", "enabled" => true, "fall" => 1, "health_check_enabled" => true, "health_check_type" => "active", "interval" => 60, "min_free_cpu" => 1.0, "min_free_mem" => 1.0, "priority" => 1, "remote_path" => "/path/on/remote", "remote_server_id" => 1, "remote_server_mount_id" => 1, "rise" => 1, "status" => "healthy", "undergoing_maintenance" => true }
    end

    params do
      requires :canary_file_path, type: String
      requires :remote_server_mount_id, type: Integer
      requires :remote_server_id, type: Integer
      optional :enabled, type: Boolean
      optional :fall, type: Integer
      optional :health_check_enabled, type: Boolean
      optional :health_check_type, type: String
      optional :interval, type: Integer
      optional :min_free_cpu, type: Float
      optional :min_free_mem, type: Float
      optional :priority, type: Integer
      optional :remote_path, type: String
      optional :rise, type: Integer
    end
    post "/api/rest/v1/remote_mount_backends" do
      status 201
      { "canary_file_path" => "backend1.txt", "enabled" => true, "fall" => 1, "health_check_enabled" => true, "health_check_type" => "active", "interval" => 60, "min_free_cpu" => 1.0, "min_free_mem" => 1.0, "priority" => 1, "remote_path" => "/path/on/remote", "remote_server_id" => 1, "remote_server_mount_id" => 1, "rise" => 1, "status" => "healthy", "undergoing_maintenance" => true }
    end

    params do
      requires :id, type: Integer
    end
    post "/api/rest/v1/remote_mount_backends/:id/reset_status" do
      status 204
      body false
    end

    params do
      requires :id, type: Integer
      requires :canary_file_path, type: String
      requires :remote_server_mount_id, type: Integer
      requires :remote_server_id, type: Integer
      optional :enabled, type: Boolean
      optional :fall, type: Integer
      optional :health_check_enabled, type: Boolean
      optional :health_check_type, type: String
      optional :interval, type: Integer
      optional :min_free_cpu, type: Float
      optional :min_free_mem, type: Float
      optional :priority, type: Integer
      optional :remote_path, type: String
      optional :rise, type: Integer
    end
    patch "/api/rest/v1/remote_mount_backends/:id" do
      status 200
      { "canary_file_path" => "backend1.txt", "enabled" => true, "fall" => 1, "health_check_enabled" => true, "health_check_type" => "active", "interval" => 60, "min_free_cpu" => 1.0, "min_free_mem" => 1.0, "priority" => 1, "remote_path" => "/path/on/remote", "remote_server_id" => 1, "remote_server_mount_id" => 1, "rise" => 1, "status" => "healthy", "undergoing_maintenance" => true }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/remote_mount_backends/:id" do
      status 204
      body false
    end
  end
end
