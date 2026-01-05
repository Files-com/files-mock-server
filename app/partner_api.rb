module FilesMockServer
  class PartnerAPI < Grape::API
    format :json

    params do
      optional :cursor, type: String
      optional :per_page, type: Integer
      optional :sort_by, type: Hash
      optional :filter, type: Hash
    end
    get "/api/rest/v1/partners" do
      status 200
      [ { "allow_bypassing_2fa_policies" => true, "allow_credential_changes" => true, "allow_providing_gpg_keys" => true, "allow_user_creation" => true, "id" => 1, "workspace_id" => 1, "name" => "Acme Corp", "notes" => "This is a note about the partner.", "partner_admin_ids" => [ 1, 2, 3 ], "root_folder" => "/AcmeCorp", "tags" => "example", "user_ids" => [ 1, 2, 3 ] } ]
    end

    params do
      requires :id, type: Integer
    end
    get "/api/rest/v1/partners/:id" do
      status 200
      { "allow_bypassing_2fa_policies" => true, "allow_credential_changes" => true, "allow_providing_gpg_keys" => true, "allow_user_creation" => true, "id" => 1, "workspace_id" => 1, "name" => "Acme Corp", "notes" => "This is a note about the partner.", "partner_admin_ids" => [ 1, 2, 3 ], "root_folder" => "/AcmeCorp", "tags" => "example", "user_ids" => [ 1, 2, 3 ] }
    end

    params do
      optional :allow_bypassing_2fa_policies, type: Boolean
      optional :allow_credential_changes, type: Boolean
      optional :allow_providing_gpg_keys, type: Boolean
      optional :allow_user_creation, type: Boolean
      optional :notes, type: String
      optional :root_folder, type: String
      optional :tags, type: String
      requires :name, type: String
      optional :workspace_id, type: Integer
    end
    post "/api/rest/v1/partners" do
      status 201
      { "allow_bypassing_2fa_policies" => true, "allow_credential_changes" => true, "allow_providing_gpg_keys" => true, "allow_user_creation" => true, "id" => 1, "workspace_id" => 1, "name" => "Acme Corp", "notes" => "This is a note about the partner.", "partner_admin_ids" => [ 1, 2, 3 ], "root_folder" => "/AcmeCorp", "tags" => "example", "user_ids" => [ 1, 2, 3 ] }
    end

    params do
      requires :id, type: Integer
      optional :allow_bypassing_2fa_policies, type: Boolean
      optional :allow_credential_changes, type: Boolean
      optional :allow_providing_gpg_keys, type: Boolean
      optional :allow_user_creation, type: Boolean
      optional :notes, type: String
      optional :root_folder, type: String
      optional :tags, type: String
      optional :name, type: String
    end
    patch "/api/rest/v1/partners/:id" do
      status 200
      { "allow_bypassing_2fa_policies" => true, "allow_credential_changes" => true, "allow_providing_gpg_keys" => true, "allow_user_creation" => true, "id" => 1, "workspace_id" => 1, "name" => "Acme Corp", "notes" => "This is a note about the partner.", "partner_admin_ids" => [ 1, 2, 3 ], "root_folder" => "/AcmeCorp", "tags" => "example", "user_ids" => [ 1, 2, 3 ] }
    end

    params do
      requires :id, type: Integer
    end
    delete "/api/rest/v1/partners/:id" do
      status 204
      body false
    end
  end
end
