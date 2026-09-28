module FilesMockServer
  module Simulation
    # Opaque handles the simulator gives clients: list cursors, upload refs and the upload and download
    # URLs built from them. Each one encodes its scope (what it names, the simulator instance and the
    # reset epoch) ahead of its values, so a handle is accepted only by the simulator process that issued
    # it and only until the next reset, even though sequence numbers restart at every reset.
    module Token
      module_function

      def encode(*fields)
        fields.join(":").unpack1("H*")
      end

      # The values after the expected scope, or nil for a handle that is malformed or has another scope.
      def values(token, *scope)
        return unless token.is_a?(String) && token.match?(/\A(?:[0-9a-f]{2}){1,128}\z/)

        fields = [ token ].pack("H*").split(":", -1)
        fields.drop(scope.size) if fields.first(scope.size) == scope.map(&:to_s)
      end
    end
  end
end
