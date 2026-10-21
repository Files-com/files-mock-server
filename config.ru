$LOAD_PATH.push __dir__

require 'lib/server_mode'

if FilesMockServer.mode == "simulation"
  require 'lib/simulation'

  begin
    app = FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.from_env, transfer_origin: ENV.fetch("FILES_MOCK_TRANSFER_ORIGIN", nil), instance: ENV.fetch("FILES_MOCK_INSTANCE", nil))
  rescue ArgumentError => e
    abort e.message
  end
  run app
else
  require 'files-mock-server'

  map "/__files_mock/download" do
    run ->(_env) { [ 200, { "content-type" => "application/octet-stream" }, [ "\x00\xffmock file\n".b ] ] }
  end
  map "/" do
    run FilesMockServer::API
  end
end
