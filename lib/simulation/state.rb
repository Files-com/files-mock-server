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

    # Everything a reset replaces: the profile, records, uploads, files, folders, list cursors, file
    # migrations, locks and the lock clock, download request IDs and the download URLs they may be
    # looked up at, counters, request sequence, journal and fault rules.
    class State
      attr_reader :epoch, :started, :records, :last_ids, :singletons, :path_records, :responses, :uploads, :files, :folders, :cursors, :cursor_aliases,
                  :migrations, :file_metadata, :locks, :download_requests, :download_transfers, :journal, :faults, :most_parts_in_flight
      attr_accessor :profile, :last_upload_id, :commits, :last_cursor_id, :last_migration_id, :last_lock_id, :lock_clock, :last_download_request_id,
                    :request_count

      def initialize(epoch, limits, fault_match_keys, profile)
        @epoch = epoch
        @started = Process.clock_gettime(Process::CLOCK_MONOTONIC) # journal times count from here
        @profile = profile
        @records = {} # resource => { id => attributes }, in creation (and therefore ID) order
        @last_ids = {} # resource => the last id it allocated; ids are never reused before a reset
        @singletons = {} # resource => attributes, such as the site's
        @path_records = {} # resource => { path => attributes }, such as styles
        @responses = {} # fixture response operation => { key => answer }
        @file_metadata = {} # path => { "custom_metadata", "priority_color" } a file or folder was given
        @uploads = {} # upload number => Files::Upload not yet finalized
        @most_parts_in_flight = 0 # the most parts holding a place at once in this state (Files#admit)
        @last_upload_id = 0
        @files = {} # path => the file's current Files::Version
        @folders = {} # path => Namespace::Folder; the root is not stored
        @cursors = {} # cursor number => Namespace::Cursor, for folder listings
        @last_cursor_id = 0
        @cursor_aliases = [] # the cursor (or "" for the first page) each empty_page answer's cursor stands for
        @migrations = {} # FileMigration id => Files::Migration, for copies and moves answered as pending
        @last_migration_id = 0
        @locks = {} # lock number => Locks::Lock, expired ones included until a cleanup removes them
        @last_lock_id = 0
        @lock_clock = 0 # seconds; only the lock clock control moves it (Locks)
        @download_requests = {} # download request number => Files::DownloadRequest, oldest first, the newest FILES_MOCK_MAX_RECORDS kept
        @last_download_request_id = 0
        @download_transfers = {} # download URL token => true for each URL files.download issued, oldest first, the newest FILES_MOCK_MAX_RECORDS kept
        @commits = 0 # new file versions (finalized uploads, copies, file fixtures); each one numbers its version
        @request_count = 0
        @journal = Journal.new(limits.max_journal_entries)
        @faults = FaultRules.new(fault_match_keys)
        @credentials = {} # SHA-256 of a credential => its number; the credential itself is never kept
      end

      # Distinct API keys and sessions numbered between resets: a test's synthetic identities.
      MAX_CREDENTIALS = 100

      # Numbers the API keys and sessions requests carry, 1, 2, ... in the order they first appear, so
      # the journal and fault schedules can tell them apart without holding them. A new one past
      # MAX_CREDENTIALS is refused before its request changes anything.
      def credential_number(credential)
        digest = Digest::SHA256.hexdigest(credential)
        return @credentials[digest] if @credentials.key?(digest)
        raise Error.limit_exceeded(409, "At most #{MAX_CREDENTIALS} distinct API keys and sessions are numbered between resets") if @credentials.size >= MAX_CREDENTIALS

        @credentials[digest] = @credentials.size + 1
      end

      # Records how many parts hold a place now, as Files#admit counts them when it admits one.
      def observe_parts_in_flight(count)
        @most_parts_in_flight = count if count > @most_parts_in_flight
      end

      # The number a credential already has, or nil.
      def known_credential_number(credential)
        @credentials[Digest::SHA256.hexdigest(credential)]
      end

      def credential_count
        @credentials.size
      end

      def users
        @records.fetch(Users::RESOURCE, {})
      end
    end
  end
end
