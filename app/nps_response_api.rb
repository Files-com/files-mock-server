module FilesMockServer
  class NpsResponseAPI < Grape::API
    format :json

    params do
      optional :user_id, type: Integer
      optional :score, type: Integer
      optional :skipped, type: Boolean
    end
    post "/api/rest/v1/nps_responses" do
      status 201
      { "id" => 1, "next_step" => "example" }
    end

    params do
      requires :id, type: Integer
      requires :comment, type: String
      optional :contact_me, type: Boolean
    end
    patch "/api/rest/v1/nps_responses/:id" do
      status 200
      { "id" => 1, "next_step" => "example" }
    end
  end
end
