module FilesMockServer
  MODES = %w[legacy simulation].freeze

  # FILES_MOCK_MODE is read once at startup. Unset, empty or "legacy" serves the fixed example
  # responses; "simulation" serves the stateful simulator. Any other value stops startup.
  def self.mode(env = ENV)
    value = env["FILES_MOCK_MODE"].to_s
    return "legacy" if value.empty?
    return value if MODES.include?(value)

    abort "FILES_MOCK_MODE=#{value.inspect} is not a valid mode. Use \"simulation\", or leave it unset (or \"legacy\") for the legacy example server."
  end
end
