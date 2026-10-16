require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require_relative "../with-scenario"

class ScenarioRunTest < Minitest::Test
  def test_readiness_must_be_observed_before_the_startup_deadline
    [ 29.5, 30.0, 30.5 ].each do |observed_at|
      Dir.mktmpdir do |directory|
        schema = "a" * 64
        instance = "123456abcdef"
        scenario = File.join(directory, "scenario.json")
        File.write(scenario, JSON.generate("name" => "readiness", "reset" => {}))
        run = ScenarioRun.new(scenario: scenario, out: File.join(directory, "out"), schema: schema,
                              command: [ "unused" ], startup: 30, consumer: 200, settle: 5
        )
        run.instance_variable_set(:@instance, instance)
        ready = { "status" => "ready", "mode" => "simulation", "contract_version" => 3,
                  "schema_sha256" => schema, "instance" => instance }
        response = Struct.new(:code, :body).new("200", JSON.generate(ready))
        now = 0.0
        # The HTTP response and monotonic clock are boundaries; admission uses the real launcher.
        request = lambda do |*_args, **_kwargs|
          now = observed_at
          response
        end
        run.stub(:clock, -> { now }) do
          run.stub(:check_server, nil) do
            run.stub(:request, request) do
              capture_io do
                if observed_at < 30
                  assert_equal ready, run.send(:wait_ready)
                else
                  error = assert_raises(ScenarioRun::SetupError) { run.send(:wait_ready) }
                  assert_includes error.message, "not ready within 30 s"
                end
              end
            end
          end
        end
      end
    end
  end
end
