require_relative "../lib/server_mode"

if FilesMockServer.mode == "simulation"
  require_relative "../lib/simulation/limits"

  begin
    limits = FilesMockServer::Simulation::Limits.from_env
  rescue ArgumentError => e
    abort e.message
  end
  # Simulation state lives in this one process. Listen on loopback unless `-b` chooses another
  # bind, and refuse to fork workers that would each hold a separate copy of the state.
  bind "tcp://127.0.0.1:4041"
  # Puma answers 413 itself for a body over the limit: a declared Content-Length before the body is
  # read, and a chunked body as soon as it crosses the limit.
  http_content_length_limit limits.max_body_bytes
  silence_fork_callback_warning
  before_fork do
    abort "FILES_MOCK_MODE=simulation keeps its state in one process; run Puma without workers (no -w or WEB_CONCURRENCY)."
  end
else
  # Keep the legacy IPv4 bind; Puma 8 otherwise defaults to :: on hosts with IPv6 interfaces.
  port 4041, "0.0.0.0"
end
