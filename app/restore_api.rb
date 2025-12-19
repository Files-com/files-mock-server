module FilesMockServer
  class RestoreAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/restores" do
      status 200
      [ { "earliest_date" => "2000-01-01T01:00:00Z", "id" => 1, "dirs_restored" => 1, "dirs_errored" => 1, "dirs_total" => 1, "files_restored" => 1, "files_errored" => 1, "files_total" => 1, "prefix" => "foo/bar/baz.txt", "restoration_type" => "files", "restore_in_place" => true, "restore_deleted_permissions" => true, "users_restored" => 1, "users_errored" => 1, "users_total" => 1, "api_keys_restored" => 1, "public_keys_restored" => 1, "two_factor_authentication_methods_restored" => 1, "status" => "pending", "update_timestamps" => true, "error_messages" => [ "example" ] } ]
    end

    params do
      requires :earliest_date, type: String
      optional :prefix, type: String
      optional :restoration_type, type: String
      optional :restore_deleted_permissions, type: Boolean
      optional :restore_in_place, type: Boolean
      optional :update_timestamps, type: Boolean
    end
    post "/api/rest/v1/restores" do
      status 201
      { "earliest_date" => "2000-01-01T01:00:00Z", "id" => 1, "dirs_restored" => 1, "dirs_errored" => 1, "dirs_total" => 1, "files_restored" => 1, "files_errored" => 1, "files_total" => 1, "prefix" => "foo/bar/baz.txt", "restoration_type" => "files", "restore_in_place" => true, "restore_deleted_permissions" => true, "users_restored" => 1, "users_errored" => 1, "users_total" => 1, "api_keys_restored" => 1, "public_keys_restored" => 1, "two_factor_authentication_methods_restored" => 1, "status" => "pending", "update_timestamps" => true, "error_messages" => [ "example" ] }
    end
  end
end
