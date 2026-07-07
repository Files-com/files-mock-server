module FilesMockServer
  class CrashReportAPI < Grape::API
    format :json

    params do
      requires :build, type: String
      requires :platform, type: String
      requires :product_name, type: String
      requires :version, type: String
      optional :comment, type: String
      optional :email, type: String
      optional :platform_version, type: String
      optional :release_channel, type: String
      optional :dump_file, type: File
      optional :log_file, type: File
    end
    post "/api/rest/v1/crash_reports" do
      status 201
      { "id" => 1 }
    end
  end
end
