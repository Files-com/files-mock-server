module FilesMockServer
  class RestoreAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
    end
    get "/api/rest/v1/restores" do
      status 200
      [ { "earliest_date" => "2000-01-01T01:00:00Z", "id" => 1, "dirs_restored" => 1, "dirs_errored" => 1, "dirs_total" => 1, "files_restored" => 1, "files_errored" => 1, "files_total" => 1, "prefix" => "foo/bar/baz.txt", "restore_in_place" => true, "restore_deleted_permissions" => true, "status" => "pending", "update_timestamps" => true, "error_messages" => [ "example" ] } ]
    end

    params do
      requires :earliest_date, type: String
      optional :restore_deleted_permissions, type: Boolean
      optional :restore_in_place, type: Boolean
      optional :prefix, type: String
    end
    post "/api/rest/v1/restores" do
      status 201
      { "earliest_date" => "2000-01-01T01:00:00Z", "id" => 1, "dirs_restored" => 1, "dirs_errored" => 1, "dirs_total" => 1, "files_restored" => 1, "files_errored" => 1, "files_total" => 1, "prefix" => "foo/bar/baz.txt", "restore_in_place" => true, "restore_deleted_permissions" => true, "status" => "pending", "update_timestamps" => true, "error_messages" => [ "example" ] }
    end
  end
end
