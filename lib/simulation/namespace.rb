module FilesMockServer
  module Simulation
    # The simulated site's files and folders, by path. Folders are records: a write creates any
    # missing parent folders (as on a site whose "always create parent folders" setting is on, so a
    # request's mkdir_parents has no further effect; the profile's site_policy can turn the setting
    # off, see Profile::SitePolicy and Files#refuse_missing_parents), a folder stays after its last file is deleted,
    # it is listed, and it is deleted only when empty. Files and folders together are limited to
    # FILES_MOCK_MAX_RECORDS.
    #
    # Paths keep the exact spelling clients send. The simulator accepts only paths already in the
    # form the Files.com API normalizes paths to, because the API would silently rewrite any other
    # form, and it refuses the names the API rejects as ambiguous rather than simulate that
    # rejection. To find the paths the API would treat as the same, it compares them as the API does
    # (PathComparison): a path that compares equal to an existing file or folder spelled differently
    # is refused as not simulated.
    #
    # Methods run under the App's lock, and each one either raises before changing anything or
    # completes.
    class Namespace
      # The root folder is stored nowhere. A request names it "/", and it is presented with an empty path.
      ROOT = "".freeze
      ROOT_SPELLING = "/".freeze
      # Files.com API list page sizes.
      DEFAULT_PER_PAGE = 1_000
      MAX_PER_PAGE = 10_000
      # Listing cursors issued between resets. Each one names a position in one folder's listing.
      MAX_CURSORS = 1_000
      # The one character the API's path helper refuses anywhere in a request's path
      # (GeneralHelpers::BAD_ZWS_CHAR).
      ZERO_WIDTH_SPACE = "\u200B".freeze

      Folder = Data.define(:path, :mtime, :provided_mtime)
      ROOT_FOLDER = Folder.new(path: ROOT, mtime: nil, provided_mtime: nil)
      # A listing continues after the entry with sort key `after`, in `folder`, at `per_page`.
      Cursor = Data.define(:folder, :per_page, :after)

      def initialize(max_records:, instance:)
        @paths = PathComparison.shared
        @max_records = max_records
        @instance = instance
      end

      # The name a request's path gives, after checking it: "/" names the root where `root` allows it.
      # `route` also applies the API's request-path rules (GeneralHelpers#path) to a route's path:
      # :folder on the folders endpoints, which check every name of it, and :file on any other route,
      # which checks the names above the last. It is nil for a path no route names, such as a
      # fixture's, a destination or a ZIP selection, which those rules do not read.
      def request_path(path, root: false, route: nil)
        return ROOT if root && path == ROOT_SPELLING

        check_path(path, route)
        path
      end

      # The API's rule for the names of a path (Path.has_trailing_space?): none may end in whitespace.
      def refuse_trailing_whitespace(names)
        raise Error.path_cannot_have_trailing_whitespace if names.split("/").any? { |name| name.match?(/\s$/) }
      end

      # The file (a Files::Version) or folder at exactly this path, or nil. Raises when the API would
      # treat the path as another spelling of an existing file or folder.
      def find(state, path)
        return ROOT_FOLDER if path == ROOT

        exact = state.files[path] || state.folders[path]
        return exact if exact

        key = @paths.key(path)
        other = records(state).find { |record| @paths.key(record.path) == key }
        raise Error.not_supported("The Files.com API treats #{path} as #{other.path}; the simulator does not simulate other spellings of a path") if other

        nil
      end

      # The folders a write at path must create, outermost first. Raises before anything changes when
      # a parent is a file: the API refuses a file as the immediate parent, and what it does with a
      # file further up is not simulated.
      def missing_parents(state, path)
        ancestors = ancestors(path)
        ancestors.each_with_index.filter_map do |ancestor, index|
          case find(state, ancestor)
          when Folder then nil
          when nil then ancestor
          else
            raise Error.folder_must_not_be_a_file if index == ancestors.size - 1

            raise Error.not_supported("#{path} would be inside the file #{ancestor}; the simulator does not simulate that")
          end
        end
      end

      # Refuses, before anything changes, a write that would hold more files and folders than the limit.
      def reserve(state, added)
        return if state.files.size + state.folders.size + added <= @max_records

        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} files and folders (FILES_MOCK_MAX_RECORDS)")
      end

      # Creates parent folders that missing_parents returned and reserve made room for.
      def add_parents(state, paths)
        paths.each { |path| state.folders[path] = Folder.new(path:, mtime: now, provided_mtime: nil) }
      end

      # Creates exactly this folder and its missing parents. Whatever already holds the name, file or
      # folder, is refused and never adopted.
      def create_folder(state, path, provided_mtime)
        raise Error.destination_exists if path == ROOT || find(state, path)

        parents = missing_parents(state, path)
        reserve(state, parents.size + 1)
        add_parents(state, parents)
        state.folders[path] = Folder.new(path:, mtime: now, provided_mtime:)
      end

      # Deletes an empty folder. The root, and a folder holding any file or folder, are refused.
      def remove_folder(state, folder)
        raise Error.folder_not_empty(folder.path) if folder.path == ROOT || children(state, folder.path).any?

        state.folders.delete(folder.path)
      end

      # [ folders, files ] strictly inside a folder at any depth: "a/b" and "a/b/c" are inside "a",
      # "ab" is not. Folders come outermost first.
      def subtree(state, folder)
        prefix = "#{folder}/"
        folders = state.folders.values.select { |record| record.path.start_with?(prefix) }.sort_by { |record| record.path.count("/") }
        [ folders, state.files.values.select { |record| record.path.start_with?(prefix) } ]
      end

      # Whether path is ancestor itself or lies inside it.
      def within?(path, ancestor)
        path == ancestor || path.start_with?("#{ancestor}/")
      end

      # A folder at a new path, as a move keeps it (its times) or a copy makes it (created now, with the source's provided_mtime).
      def relocated_folder(folder, path, copy:)
        Folder.new(path:, mtime: copy ? now : folder.mtime, provided_mtime: folder.provided_mtime)
      end

      # Returns [ one page of the folder's files and folders in path order, cursor for the next page
      # or nil ]. A cursor continues after the last entry its page returned, so entries created during
      # a traversal appear on later pages when they sort after it, entries deleted before they are
      # reached are skipped, and no entry is returned twice. The last page names no cursor. With
      # folders_only, a page that would hold a file is refused before a cursor is issued for it.
      def list(state, folder, per_page, cursor, folders_only: false)
        per_page = page_size(per_page)
        after = continuation(state, cursor, folder, per_page) unless cursor.nil? || cursor == ""
        entries = children(state, folder).sort_by { |record| sort_key(record) }
        entries = entries.drop_while { |record| (sort_key(record) <=> after) <= 0 } if after
        page = entries.first(per_page)
        raise Error.not_supported("with_previews is simulated only for a page of folders; file previews are not simulated") if folders_only && !page.all?(Folder)

        [ page, (issue_cursor(state, folder, per_page, sort_key(page.last)) if entries.size > per_page) ]
      end

      def readiness(state)
        {
          "site_policy" => state.profile.site_policy.as_json,
          "listing" => { "order" => "path", "default_per_page" => DEFAULT_PER_PAGE, "max_per_page" => MAX_PER_PAGE, "max_cursors" => MAX_CURSORS,
                         "next_cursor_headers" => [ "X-Files-Cursor", "X-Files-Cursor-Next" ] },
          "delete" => { "recursive" => true, "root" => false },
          "state" => { "files" => state.files.size, "folders" => state.folders.size, "cursors" => state.cursors.size },
        }
      end

      private

      def records(state)
        state.files.values + state.folders.values
      end

      def children(state, folder)
        records(state).select { |record| parent(record.path) == folder }
      end

      # Names sort as the API compares them, then by their exact spelling.
      def sort_key(record)
        [ @paths.key(record.path), record.path ]
      end

      def parent(path)
        path.include?("/") ? path.rpartition("/").first : ROOT
      end

      # "a" and "a/b" for "a/b/c".
      def ancestors(path)
        names = path.split("/")
        (1...names.size).map { |count| names.first(count).join("/") }
      end

      def page_size(value)
        return DEFAULT_PER_PAGE if value.nil?
        raise Error.request_params_invalid("per_page must be greater than or equal to 1") if value < 1
        raise Error.request_params_invalid("per_page must be less than or equal to #{MAX_PER_PAGE}") if value > MAX_PER_PAGE

        value
      end

      # The same position in the same listing always gets the same cursor.
      def issue_cursor(state, folder, per_page, after)
        position = Cursor.new(folder:, per_page:, after:)
        number = state.cursors.key(position)
        unless number
          raise Error.limit_exceeded(409, "At most #{MAX_CURSORS} folder listing cursors are issued between resets") if state.cursors.size >= MAX_CURSORS

          number = state.last_cursor_id += 1
          state.cursors[number] = position
        end
        state.profile.cursor(Token.encode("folders", @instance, state.epoch, number))
      end

      # A cursor is valid only for the simulator process, reset epoch, folder and page size it was issued for.
      def continuation(state, token, folder, per_page)
        values = Token.values(state.profile.token_of(token), "folders", @instance, state.epoch)
        number = Integer(values.first, 10) if values&.size == 1 && values.first.match?(/\A[1-9][0-9]*\z/)
        position = state.cursors[number]
        raise Error.invalid_cursor unless position && position.folder == folder && position.per_page == per_page

        position.after
      end

      # A form the API would rewrite is refused first, since what it becomes is not simulated; then the
      # API's request-path rules for a route's path; then the names the API rejects as ambiguous.
      def check_path(path, route)
        raise Error.bad_request("The path is not valid UTF-8") unless path.valid_encoding?

        components = path.split("/", -1)
        normalized = !components.intersect?([ "", ".", ".." ]) && !path.match?(/[\\\0]/)
        raise Error.not_supported("#{path.inspect} is not a normalized path; send it without leading, trailing or repeated slashes, dot segments or backslashes") unless normalized

        refuse_route_path(path, route) if route

        ambiguous = components.any? { |component| @paths.ambiguous?(component) }
        raise Error.not_supported("#{path.inspect} has a name the Files.com API rejects as ambiguous, one that compares as empty, \".\" or \"..\" or contains a slash; the simulator does not simulate that rejection") if ambiguous
      end

      # The API's request-path rules in its order: a name ending in whitespace (every name on the
      # folders endpoints, those above the last on any other route), then a zero-width space anywhere.
      def refuse_route_path(path, route)
        refuse_trailing_whitespace(route == :folder ? path : File.dirname(path))
        raise Error.invalid_path if path.include?(ZERO_WIDTH_SPACE)
      end

      def now
        Time.now.utc.strftime("%FT%TZ")
      end
    end
  end
end
