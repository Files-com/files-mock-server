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

  # A caller's own bundle, such as the generator's `bundle exec`, puts its gem paths, load path and preload in the
  # launcher's environment in place of the caller's. The server's `bundle exec`, here a stand-in that records the
  # environment it was given, starts from the caller's environment before that bundle: the caller's own RUBYOPT, RUBYLIB
  # and bundle settings and none of the generator bundle's gem paths, then the mock's Gemfile, mode and this run's
  # instance. The launcher's own environment, which the consumer inherits, is left as it was.
  def test_the_server_starts_from_the_callers_environment_before_its_bundle
    Dir.mktmpdir do |directory|
      record = File.join(directory, "server-environment.json")
      bundle = File.join(directory, "bin", "bundle")
      FileUtils.mkdir_p(File.dirname(bundle))
      File.write(bundle, <<~ruby)
        #!#{RbConfig.ruby}
        require "json"
        File.write(#{record.inspect}, JSON.generate(ENV.to_h))
      ruby
      File.chmod(0o755, bundle)
      scenario = File.join(directory, "scenario.json")
      File.write(scenario, JSON.generate("name" => "server-environment", "reset" => {}))
      caller_settings = { "PATH" => [ File.dirname(bundle), ENV.fetch("PATH") ].join(File::PATH_SEPARATOR),
                          "BUNDLE_PATH" => File.join(directory, "caller-bundle"), "BUNDLE_FROZEN" => "true" }
      # The caller's own preload and load path, which the generator bundle's replaced in the launcher's environment.
      caller_preloads = { "RUBYOPT" => "-w", "RUBYLIB" => File.join(directory, "caller-lib") }
      generator_bundle = { "GEM_HOME" => File.join(directory, "generator-gems"), "GEM_PATH" => File.join(directory, "generator-gems"),
                           "RUBYLIB" => File.join(directory, "generator-bundler"), "RUBYOPT" => "-rbundler/setup",
                           "BUNDLER_SETUP" => File.join(directory, "generator-bundler", "bundler", "setup") }
      # The caller's environment from before any bundle, as Bundler recorded it when it loaded, with the caller's own
      # settings. None of the generator bundle's keys carry over: RubyGems requires a BUNDLER_SETUP it is started with.
      original = Bundler.original_env.except(*generator_bundle.keys).merge(caller_settings, caller_preloads)
      saved = ENV.to_h
      begin
        ENV.update(caller_settings.merge(generator_bundle, "BUNDLE_GEMFILE" => File.join(directory, "Gemfile")))
        launcher = ENV.to_h
        run = ScenarioRun.new(scenario: scenario, out: File.join(directory, "out"), schema: "a" * 64,
                              command: [ "unused" ], startup: 30, consumer: 30, settle: 5
        )
        run.instance_variable_set(:@leaders, {})
        # Bundler reports the caller's environment from before its bundle; this test chooses that environment.
        Bundler.stub(:original_env, original) { capture_io { run.send(:start_server) } }
        _, status = Process.wait2(run.instance_variable_get(:@server_pid))

        assert_predicate status, :success?
        assert(launcher == ENV.to_h, "launcher environment changed")
      ensure
        ENV.replace(saved)
      end
      server = JSON.parse(File.read(record))
      expected = { "BUNDLE_GEMFILE" => File.join(ScenarioRun::MOCK_DIR, "Gemfile"), "FILES_MOCK_MODE" => "simulation",
                   "FILES_MOCK_INSTANCE" => run.instance_variable_get(:@instance) }.merge(caller_settings, caller_preloads)

      assert_empty server.slice("GEM_HOME", "GEM_PATH", "BUNDLER_SETUP")
      assert_equal expected, server.slice(*expected.keys)
    end
  end
end
