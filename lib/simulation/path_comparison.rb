module FilesMockServer
  module Simulation
    # How the Files.com API compares paths: each Unicode scalar is replaced once, in order, from the
    # shared version 1 map for MySQL utf8mb4_0900_ai_ci that the generator copies into shared/ (see
    # shared/path_comparison.md). The simulator uses the comparison only to refuse paths it does not
    # model: names the API rejects as ambiguous, and other spellings of existing files and folders.
    # Stored paths keep the exact spelling clients send.
    class PathComparison
      DATA_PATH = File.expand_path("../../shared/path_comparison.json", __dir__)
      FORMAT = { "version" => 1, "collation" => "utf8mb4_0900_ai_ci" }.freeze
      # Printable ASCII other than capital letters compares as itself, so only other characters are looked up.
      LOOKED_UP = /[^ -@\[-~]/

      # The comparison from the map packaged with this server, loaded once per process.
      def self.shared
        @shared ||= new(DATA_PATH)
      end

      # Raises ArgumentError, which stops startup, rather than compare paths any other way.
      def initialize(data_path)
        data = JSON.parse(File.read(data_path))
        valid = data.is_a?(Hash) && data.slice(*FORMAT.keys) == FORMAT && data["mapping"].is_a?(Hash) && data["mapping"].each_value.all?(String)
        raise ArgumentError, "it is not version 1 of the utf8mb4_0900_ai_ci comparison map" unless valid

        @mapping = data["mapping"].to_h { |hex, replacement| [ Integer(hex, 16).chr(Encoding::UTF_8), replacement.freeze ] }.freeze
      rescue SystemCallError, JSON::ParserError, ArgumentError, RangeError => e
        raise ArgumentError, "Simulation mode compares paths the way the Files.com API does, with #{data_path}, which could not be used: #{e.message}. " \
                             "Regenerate the server from the generator, which copies this file from targets/common/shared."
      end

      # Two paths name the same file in the API when their keys are equal.
      def key(path)
        path.gsub(LOOKED_UP) { |character| @mapping.fetch(character, character) }
      end

      # A path component the API rejects as ambiguous: compared, and without trailing whitespace, it is
      # empty, "." or "..", or it contains a slash or backslash.
      def ambiguous?(component)
        compared = key(component).rstrip
        compared.empty? || compared == "." || compared == ".." || compared.match?(/[\/\\]/)
      end
    end
  end
end
