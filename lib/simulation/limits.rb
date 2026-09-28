module FilesMockServer
  module Simulation
    # Resource bounds for one simulator process. Requests that would exceed them are rejected;
    # nothing is silently truncated. These protect the test host and are not Files.com API limits.
    class Limits
      # name => [ environment variable, default, largest accepted value ]
      SETTINGS = {
        max_records: [ "FILES_MOCK_MAX_RECORDS", 1_000, 100_000 ],
        max_journal_entries: [ "FILES_MOCK_MAX_JOURNAL_ENTRIES", 10_000, 100_000 ],
        max_body_bytes: [ "FILES_MOCK_MAX_BODY_BYTES", 1_048_576, 16_777_216 ],
        max_transfer_bytes: [ "FILES_MOCK_MAX_TRANSFER_BYTES", 33_554_432, 1_073_741_824 ],
      }.freeze

      attr_reader(*SETTINGS.keys)

      def self.from_env(env = ENV)
        values = SETTINGS.each_with_object({}) do |(name, (variable, _default, maximum)), result|
          next unless env.key?(variable)
          raise ArgumentError, "#{variable} must be a whole number from 1 to #{maximum}" unless env[variable].match?(/\A[1-9][0-9]*\z/)

          result[name] = Integer(env[variable], 10)
        end
        new(**values)
      end

      def initialize(**values)
        unknown = values.keys - SETTINGS.keys
        raise ArgumentError, "Unknown simulation limits: #{unknown.join(", ")}" if unknown.any?

        SETTINGS.each do |name, (variable, default, maximum)|
          value = values.fetch(name, default)
          raise ArgumentError, "#{variable} must be a whole number from 1 to #{maximum}" unless value.is_a?(Integer) && value.between?(1, maximum)

          instance_variable_set(:"@#{name}", value)
        end
      end

      def to_h
        SETTINGS.keys.to_h { |name| [ name.to_s, public_send(name) ] }
      end
    end
  end
end
