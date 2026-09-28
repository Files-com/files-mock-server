module FilesMockServer
  module Simulation
    # Bounded request journal. Entries past the limit are counted as dropped, and the journal then
    # reports itself incomplete rather than presenting a truncated record as the full history.
    class Journal
      def initialize(limit)
        @limit = limit
        @entries = []
        @dropped = 0
      end

      def record(entry)
        if @entries.size < @limit
          @entries << entry.freeze
        else
          @dropped += 1
        end
      end

      def size
        @entries.size
      end

      def complete?
        @dropped.zero?
      end

      # Copies the entry list so a response built under the App lock cannot change while it is serialized.
      def as_json
        { "entries" => @entries.dup, "limit" => @limit, "dropped" => @dropped, "complete" => complete? }
      end
    end

    # Everything a reset replaces: records, ID counter, request sequence, journal and fault rules.
    class State
      attr_reader :epoch, :users, :journal, :faults
      attr_accessor :last_user_id, :request_count

      def initialize(epoch, limits, fault_match_keys)
        @epoch = epoch
        @users = {} # id => attributes, in creation (and therefore ID) order
        @last_user_id = 0
        @request_count = 0
        @journal = Journal.new(limits.max_journal_entries)
        @faults = FaultRules.new(fault_match_keys)
      end
    end
  end
end
