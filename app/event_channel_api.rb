module FilesMockServer
  class EventChannelAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/event_channels" do
      status 200
      [ { "id" => 1, "name" => "example", "description" => "example", "enabled" => true, "default_channel" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/event_channels/:id" do
      status 200
      { "id" => 1, "name" => "example", "description" => "example", "enabled" => true, "default_channel" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :name, type: String
      optional :description, type: String
      optional :enabled, type: Boolean
      optional :default_channel, type: Boolean
    end
    post "/api/rest/v1/event_channels" do
      status 201
      { "id" => 1, "name" => "example", "description" => "example", "enabled" => true, "default_channel" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
      optional :name, type: String
      optional :description, type: String
      optional :enabled, type: Boolean
      optional :default_channel, type: Boolean
    end
    patch "/api/rest/v1/event_channels/:id" do
      status 200
      { "id" => 1, "name" => "example", "description" => "example", "enabled" => true, "default_channel" => true, "created_at" => "2000-01-01T01:00:00Z", "updated_at" => "2000-01-01T01:00:00Z" }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/event_channels/:id" do
      status 204
      body false
    end
  end
end
