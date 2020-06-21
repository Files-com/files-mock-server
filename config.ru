$LOAD_PATH.push __dir__

require 'files-mock-server'

run FilesMockServer::API
