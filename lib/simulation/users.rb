module FilesMockServer
  module Simulation
    # Users are records like any other resource, but their operations and fields come from
    # schema.json's "operations" and "entities" (the generator's SIMULATED_OPERATIONS), which the
    # simulator requires: a server generated without them refuses to start.
    module Users
      RESOURCE = "users".freeze
      ACTIONS = %w[create list find update delete].freeze

      def self.build(schema, max_records:)
        operations = schema.fetch("operations")
        definition = {
          "path" => "/#{RESOURCE}", "key" => "id",
          "operations" => ACTIONS.to_h { |action| [ action, operations.fetch("#{RESOURCE}.#{action}") ] },
          "properties" => schema.fetch("entities").fetch(RESOURCE).to_h { |field| [ field, {} ] },
        }
        Records.new(RESOURCE, definition, max_records:)
      end
    end
  end
end
