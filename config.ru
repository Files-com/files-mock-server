$LOAD_PATH.push __dir__

require 'lib/server_mode'

if FilesMockServer.mode == "simulation"
  require 'lib/simulation'

  begin
    app = FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.from_env)
  rescue ArgumentError => e
    abort e.message
  end
  run app
else
  require 'files-mock-server'

  run FilesMockServer::API
end
