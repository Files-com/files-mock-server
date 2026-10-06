require_relative "test_helper"

# Copies, moves and recursive deletes of files and folders, the FileMigrations of pending ones, and
# file and folder fixtures.
class FileActionsTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  def setup
    @app = new_app
  end

  def test_a_file_move_renames_it_with_its_bytes_and_answers_completed
    upload("in/report.bin", [ "abc", "def" ])
    moved = action("move", "in/report.bin", "out/Report Final.bin")
    assert_equal [ 201, { "status" => "completed" } ], [ moved.status, moved.json ]
    assert_equal 404, stat("in/report.bin").status
    assert_equal [ "out/Report Final.bin", 6 ], stat("out/Report Final.bin").json.values_at("path", "size")
    assert_equal "abcdef", download("out/Report Final.bin").body
    # The source's folder stays, and the destination's missing parent was created.
    assert_equal(%w[directory directory], %w[in out].map { |path| stat(path).json["type"] })
    assert_equal [ [ 201, "file", 1, 0, 6 ] ], journaled("files.move", %w[status type files folders bytes])
  end

  def test_an_existing_destination_is_refused_unless_overwrite_replaces_it
    upload("a.bin", [ "new" ])
    upload("b.bin", [ "old" ])
    refused = action("move", "a.bin", "b.bin")
    assert_equal [ 422, "processing-failure/destination-exists", "The destination exists." ], [ refused.status, *refused.json.values_at("type", "error") ]
    assert_equal [ "new", "old" ], [ download("a.bin").body, download("b.bin").body ]

    assert_equal 201, action("move", "a.bin", "b.bin", { "overwrite" => true }).status
    assert_equal [ 404, "new" ], [ stat("a.bin").status, download("b.bin").body ]
    api("POST", "/folders/dir", {})
    conflict = action("copy", "b.bin", "dir", { "overwrite" => true })
    assert_equal [ 501, "simulation/not-supported" ], [ conflict.status, conflict.json["type"] ]
  end

  # A folder's subtree is everything under "foo/", never "foo2".
  # A destination sent null or empty passes the parameter validation and is the site root to the API,
  # which always exists: without overwrite a copy or move is refused as an existing destination; with
  # overwrite the API enqueues it, and the FileMigration fails its dest_path presence validation,
  # which the API answers with its catch-all 500. A missing source is still found missing first, and
  # nothing changes or is enqueued.
  def test_copies_and_moves_to_a_destination_sent_null_or_empty_meet_the_site_root
    upload("a/b.bin", [ "b" ])
    held = control("GET", "ready").json.dig("namespace", "state")
    catch_all = { "error" => "Internal server error, please contact support or the person who created your account.", "http-code" => "500" }
    [ nil, "" ].product(%w[copy move], %w[a a/b.bin]).each do |destination, name, source|
      exists = action(name, source, destination)
      assert_equal [ 422, "processing-failure/destination-exists", "processing-failure/destination-exists" ], [ exists.status, exists.json["type"], exists.headers["x-files-error-class"] ], [ destination, name, source ].inspect
      failed = action(name, source, destination, { "overwrite" => true })
      assert_equal [ 500, catch_all, nil, "application/json" ], [ failed.status, failed.json, failed.headers["x-files-error-class"], failed.headers["content-type"] ], [ destination, name, source ].inspect
    end
    assert_equal([ 404, "not-found" ], action("move", "missing", nil, { "overwrite" => true }).then { |missing| [ missing.status, missing.json["type"] ] })
    assert_equal [ held, "b" ], [ control("GET", "ready").json.dig("namespace", "state"), download("a/b.bin").body ]

    control_reset({ "profile" => { "file_actions" => "pending" }, "fixtures" => { "files" => [ { "path" => "a/b.bin", "text" => "b" } ] } })
    assert_equal [ 500, 422 ], [ action("copy", "a", "", { "overwrite" => true }).status, action("move", "a/b.bin", nil).status ]
    assert_equal [ 0, 404 ], [ control("GET", "ready").json.dig("state", "file_migrations"), api("GET", "/file_migrations/1").status ]
  end

  def test_a_folder_move_takes_exactly_its_subtree
    upload("foo/a.bin", [ "a" ])
    upload("foo/sub/b.bin", [ "b" ])
    upload("foo2/c.bin", [ "c" ])
    upload("foo.bin", [ "d" ])
    assert_equal 201, action("move", "foo", "bar").status
    assert_equal([ 404, 404, 404 ], %w[foo foo/a.bin foo/sub].map { |path| stat(path).status })
    assert_equal [ "a", "b" ], [ download("bar/a.bin").body, download("bar/sub/b.bin").body ]
    assert_equal [ "c", "d" ], [ download("foo2/c.bin").body, download("foo.bin").body ]
    assert_equal [ [ "directory", 2, 2, 2 ] ], journaled("files.move", %w[type files folders bytes])
  end

  def test_a_folder_copy_keeps_the_source_and_counts_the_copied_bytes
    upload("src/one.bin", [ "12345" ])
    upload("src/deep/two.bin", [ "678" ])
    api("POST", "/folders/src/empty", {})
    before = bytes_in_use
    copied = action("copy", "src", "dst", { "copy_behaviors" => false })
    assert_equal [ 201, { "status" => "completed" } ], [ copied.status, copied.json ]
    assert_equal before + 8, bytes_in_use
    assert_equal([ "12345", "678", "12345", "678" ], %w[src/one.bin src/deep/two.bin dst/one.bin dst/deep/two.bin].map { |path| download(path).body })
    assert_equal "directory", stat("dst/empty").json["type"]
    # A copy is a new version: deleting the source leaves it, and its bytes, in place.
    assert_equal 204, api("DELETE", "/files/src", { "recursive" => true }).status
    assert_equal [ "12345", before + 8 - 8 ], [ download("dst/one.bin").body, bytes_in_use ]
  end

  def test_structure_copies_only_the_folders
    upload("tree/x/file.bin", [ "x" ])
    assert_equal 201, action("copy", "tree", "shape", { "structure" => true }).status
    assert_equal [ "directory", "directory", 404 ], [ stat("shape").json["type"], stat("shape/x").json["type"], stat("shape/x/file.bin").status ]
    file = action("copy", "tree/x/file.bin", "other.bin", { "structure" => true })
    assert_equal 501, file.status
  end

  def test_overwriting_a_folder_merges_into_it_and_replaces_same_named_files
    upload("new/same.bin", [ "new" ])
    upload("new/only-new.bin", [ "n" ])
    upload("old/same.bin", [ "old" ])
    upload("old/only-old.bin", [ "o" ])
    refused = action("copy", "new", "old")
    assert_equal 422, refused.status
    assert_equal 201, action("copy", "new", "old", { "overwrite" => true }).status
    assert_equal([ "new", "n", "o" ], %w[old/same.bin old/only-new.bin old/only-old.bin].map { |path| download(path).body })
  end

  def test_copies_and_moves_refuse_what_is_not_simulated_before_any_change
    upload("a/b/c.bin", [ "c" ])
    {
      "into itself" => [ action("move", "a", "a/b/inside"), 501, "simulation/not-supported" ],
      "onto a folder that holds it" => [ action("copy", "a/b", "a", { "overwrite" => true }), 501, "simulation/not-supported" ],
      "copy_behaviors" => [ action("copy", "a", "z", { "copy_behaviors" => true }), 501, "simulation/not-supported" ],
      "a missing source" => [ action("move", "missing", "z"), 404, "not-found" ],
      "no destination" => [ api("POST", "/file_actions/move/a", {}), 422, "bad-request" ],
      "the root" => [ api("POST", "/file_actions/copy/%2F", { "destination" => "z" }), 501, "simulation/not-supported" ],
      "an unnormalized destination" => [ action("copy", "a", "z/"), 501, "simulation/not-supported" ],
      "a destination inside a file" => [ action("copy", "a", "a/b/c.bin/z"), 501, "simulation/not-supported" ],
      "an unreadable overwrite" => [ action("move", "a", "z", { "overwrite" => "sometimes" }), 422, "bad-request" ],
      "a copy into a folder name ending in whitespace" => [ action("copy", "a", "z /a"), 422, "bad-request/path-cannot-have-trailing-whitespace" ],
      "a move into a folder name ending in whitespace" => [ action("move", "a/b/c.bin", "y /c.bin"), 422, "bad-request/path-cannot-have-trailing-whitespace" ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
    end
    assert_equal({ "files" => 1, "folders" => 2, "cursors" => 0 }, control("GET", "ready").json.dig("namespace", "state"))
  end

  def test_copies_and_moves_stay_within_the_record_and_byte_limits
    simulator = new_app(max_records: 4, max_transfer_bytes: 10)
    reset({ "files" => [ { "path" => "d/a.bin", "text" => "123456" } ] }, to: simulator)
    too_many = action("copy", "d", "e/f", to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ too_many.status, too_many.json["type"] ]
    assert_equal 201, action("move", "d", "e", to: simulator).status
    too_large = action("copy", "e/a.bin", "a.bin", to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ too_large.status, too_large.json["type"] ]
    assert_equal({ "files" => 1, "folders" => 1, "cursors" => 0 }, control("GET", "ready", to: simulator).json.dig("namespace", "state"))
  end

  def test_a_recursive_delete_removes_exactly_the_subtree_and_releases_its_bytes
    upload("foo/a.bin", [ "aaaa" ])
    upload("foo/sub/b.bin", [ "bb" ])
    upload("foo2/c.bin", [ "c" ])
    upload("foo.bin", [ "d" ])
    before = bytes_in_use
    refused = api("DELETE", "/files/foo", { "recursive" => false })
    assert_equal [ 422, "processing-failure/folder-not-empty" ], [ refused.status, refused.json["type"] ]
    assert_equal 204, api("DELETE", "/files/foo", { "recursive" => "True" }).status
    assert_equal([ 404, 404, 404 ], %w[foo foo/a.bin foo/sub/b.bin].map { |path| stat(path).status })
    assert_equal [ "c", "d", before - 6 ], [ download("foo2/c.bin").body, download("foo.bin").body, bytes_in_use ]
    assert_equal([ [ 204, "directory", 2, 1 ] ], journaled("files.delete", %w[status type files folders]).select { |status, *| status == 204 })
    root = api("DELETE", "/files/%2F", { "recursive" => true })
    assert_equal [ 501, "simulation/not-supported" ], [ root.status, root.json["type"] ]
  end

  # A pending profile answers with a FileMigration that is processing when first polled and applied
  # when polled again, against the state at that moment.
  def test_a_pending_copy_is_applied_when_its_migration_is_polled_to_completion
    control_reset({ "profile" => { "file_actions" => "pending" }, "fixtures" => { "files" => [ { "path" => "a/x.bin", "text" => "xyz" } ] } })
    assert_equal([ "pending", %w[completed pending] ], control("GET", "ready").json.then { |ready| [ ready.dig("profile", "file_actions"), ready.dig("profile_choices", "file_actions") ] })
    pending = action("copy", "a", "b")
    assert_equal [ 201, { "status" => "pending", "file_migration_id" => 1 } ], [ pending.status, pending.json ]
    assert_equal 404, stat("b").status
    assert_equal({ "id" => 1, "path" => "a", "dest_path" => "b", "operation" => "copy", "status" => "processing", "files_moved" => 0, "files_total" => 0 }, api("GET", "/file_migrations/1").json)
    assert_equal 404, stat("b").status
    completed = api("GET", "/file_migrations/1").json
    assert_equal({ "id" => 1, "path" => "a", "dest_path" => "b", "operation" => "copy", "status" => "completed", "files_moved" => 1, "files_total" => 0 }, completed)
    assert_equal "xyz", download("b/x.bin").body
    assert_equal "completed", api("GET", "/file_migrations/1").json["status"]
    assert_equal [ [ "processing", nil ], [ "completed", 1 ], [ "completed", nil ] ], journaled("file_migrations.find", %w[migration_status files])
    assert_equal 404, api("GET", "/file_migrations/2").status
  end

  # Retained migrations are bounded by FILES_MOCK_MAX_RECORDS: past it a pending action is refused
  # before anything changes, and a reset releases them.
  def test_retained_migrations_are_bounded_and_released_by_a_reset
    simulator = new_app(max_records: 4)
    body = { "profile" => { "file_actions" => "pending" }, "fixtures" => { "files" => [ { "path" => "a.bin", "text" => "a" } ] } }
    assert_equal 200, control("POST", "reset", body, to: simulator).status
    ids = 4.times.map { |number| action("copy", "a.bin", "copy-#{number}.bin", {}, to: simulator).json["file_migration_id"] }
    assert_equal [ 1, 2, 3, 4 ], ids
    refused = action("copy", "a.bin", "copy-5.bin", {}, to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ refused.status, refused.json["type"] ]
    assert_equal 409, action("copy", "a.bin", nil, { "overwrite" => true }, to: simulator).status, "the limit comes before the migration a root destination fails"
    assert_equal 4, control("GET", "ready", to: simulator).json.dig("state", "file_migrations")
    assert_equal 404, api("GET", "/file_migrations/5", nil, to: simulator).status
    assert_equal 200, control("POST", "reset", body, to: simulator).status
    assert_equal 1, action("copy", "a.bin", "again.bin", {}, to: simulator).json["file_migration_id"]
  end

  def test_a_pending_move_that_can_no_longer_apply_fails_without_any_change
    control_reset({ "profile" => { "file_actions" => "pending" }, "fixtures" => { "files" => [ { "path" => "a.bin", "text" => "a" } ] } })
    assert_equal 201, action("move", "a.bin", "b.bin").status
    upload("b.bin", [ "b" ])
    api("GET", "/file_migrations/1")
    failed = api("GET", "/file_migrations/1").json
    assert_equal [ "failed", "The destination exists." ], failed.values_at("status", "failure_message")
    assert_equal [ "a", "b" ], [ download("a.bin").body, download("b.bin").body ]
    invalid = control("POST", "reset", { "profile" => { "file_actions" => "later" } })
    assert_equal [ 400, "profile.file_actions must be one of: completed, pending" ], [ invalid.status, invalid.json["error"] ]
    assert_equal "pending", control("GET", "ready").json.dig("profile", "file_actions")
  end

  def test_file_and_folder_fixtures_load_last_and_all_or_nothing
    files = [ { "path" => "deep/f.bin", "base64" => [ "\x00\xFF".b ].pack("m0"), "provided_mtime" => "2030-01-02T03:04:05Z" }, { "path" => "t.txt", "text" => "" } ]
    loaded = reset({ "groups" => [ { "name" => "g" } ], "folders" => [ "empty", "deep/er" ], "files" => files })
    assert_equal({ "epoch" => 1, "groups" => [ 1 ], "folders" => 2, "files" => 2 }, loaded)
    assert_equal [ "\x00\xFF".b, "" ], [ download("deep/f.bin").body.b, download("t.txt").body ]
    assert_equal [ "2030-01-02T03:04:05Z", 2 ], stat("deep/f.bin").json.values_at("provided_mtime", "size")
    assert_equal "directory", stat("deep/er").json["type"]
    bytes = bytes_in_use
    {
      "a duplicate path" => [ { "files" => [ { "path" => "x", "text" => "1" }, { "path" => "x", "text" => "2" } ] }, 422, "fixtures.files[1]: Destination already exists." ],
      "both contents" => [ { "files" => [ { "path" => "x", "text" => "1", "base64" => "MQ==" } ] }, 400, "fixtures.files[0]: give exactly one of text and base64" ],
      "bad base64" => [ { "files" => [ { "path" => "x", "base64" => "!!" } ] }, 400, "fixtures.files[0]: base64 is not valid strict Base64" ],
      "no path" => [ { "files" => [ { "text" => "1" } ] }, 400, "fixtures.files[0]: path is missing" ],
      "the root folder" => [ { "folders" => [ "/" ] }, 400, "fixtures.folders must not name the root" ],
      "an invalid record after files" => [ { "files" => [ { "path" => "x", "text" => "1" } ], "groups" => [ {} ] }, 422, "fixtures.groups[0]: name is missing" ],
    }.each do |name, (fixtures, status, error)|
      refused = control("POST", "reset", { "fixtures" => fixtures })
      assert_equal [ status, error ], [ refused.status, refused.json["error"] ], name
    end
    assert_equal [ 1, bytes, 200 ], [ control("GET", "ready").json["epoch"], bytes_in_use, stat("t.txt").status ]
    over = control("POST", "reset", { "fixtures" => { "files" => [ { "path" => "big", "text" => "x" * 11 } ] } }, to: small = new_app(max_transfer_bytes: 10))
    assert_equal [ 409, "simulation/limit-exceeded" ], [ over.status, over.json["type"] ]
    assert_equal 0, control("GET", "ready", to: small).json.dig("transfers", "state", "bytes_in_use")
    # The bytes of the state a reset replaces do not count against its fixtures.
    2.times { reset({ "files" => [ { "path" => "six", "text" => "x" * 6 } ] }, to: small) }
    assert_equal 6, control("GET", "ready", to: small).json.dig("transfers", "state", "bytes_in_use")
  end

  def test_copy_and_move_faults_match_the_source_path_and_fail_before_any_change
    upload("a.bin", [ "a" ])
    add_fault({ "operation" => "files.move", "match" => { "path" => "a.bin" }, "status" => 503 })
    assert_equal 503, action("move", "a.bin", "b.bin").status
    assert_equal [ 200, 404 ], [ stat("a.bin").status, stat("b.bin").status ]
    assert_equal 201, action("move", "a.bin", "b.bin").status
  end

  # zip_list reads the archive's central directory; unzip's FileMigration extracts every file entry
  # under the destination, creating the folders their paths name, once it is polled to completion.
  def test_zip_list_lists_the_archive_and_unzip_extracts_its_files_when_the_migration_completes
    report = (0...3000).map { |index| (index * 7) % 256 }.pack("C*")
    upload("in/archive.zip", [ zip([ [ "a.txt", "hello" ], [ "docs/", "" ], [ "docs/report.bin", report, { method: 8 } ], [ "é +.txt", "unicode" ] ]) ])
    listed = api("GET", "/file_actions/zip_list/#{route("in/archive.zip")}")
    assert_equal [ 200, [ [ "a.txt", 5 ], [ "docs/", 0 ], [ "docs/report.bin", 3000 ], [ "é +.txt", 7 ] ] ], [ listed.status, listed.json.map { |entry| entry.values_at("path", "size") } ]

    started = api("POST", "/file_actions/unzip", { "path" => "in/archive.zip", "destination" => "out/x" })
    assert_equal [ 201, { "status" => "pending", "file_migration_id" => 1 } ], [ started.status, started.json ]
    # The destination folder is created with the request; the files only when the migration completes.
    assert_equal [ "directory", 404 ], [ stat("out/x").json["type"], stat("out/x/a.txt").status ]
    assert_equal "processing", api("GET", "/file_migrations/1").json["status"]
    assert_equal [ "completed", 3, 0 ], api("GET", "/file_migrations/1").json.values_at("status", "files_moved", "files_total")
    assert_equal [ "hello", report, "unicode" ], [ download("out/x/a.txt").body, download("out/x/docs/report.bin").body.b, download("out/x/é +.txt").body.force_encoding("UTF-8") ]
    assert_equal "directory", stat("out/x/docs").json["type"]
    assert_equal [ [ 200, 4 ] ], journaled("files.zip_list", %w[status entries])
    assert_equal [ [ 201, 1, true ] ], journaled("files.unzip", %w[status migration destination_created])
    assert_equal [ [ "completed", 3, 1, 3012 ] ], journaled("file_migrations.find", %w[migration_status files folders bytes]).drop(1)
  end

  # An unzip's path or destination sent null or empty passes the parameter validation and is the site
  # root: a root path is a folder, refused before any destination or migration is made, and a root
  # destination is the root folder, which the migration fills under the usual extraction rules.
  def test_unzip_reads_a_null_or_empty_path_or_destination_as_the_site_root
    upload("in/root.zip", [ zip([ [ "top.txt", "top" ], [ "nested/deep.bin", "\x00\xFF".b ] ]) ])
    [ nil, "" ].each do |path|
      refused = api("POST", "/file_actions/unzip", { "path" => path, "destination" => "out" })
      assert_equal [ 422, "bad-request/folders-not-allowed", "bad-request/folders-not-allowed" ], [ refused.status, refused.json["type"], refused.headers["x-files-error-class"] ], path.inspect
    end
    assert_equal [ 422, "destination is missing" ], api("POST", "/file_actions/unzip", { "path" => nil }).json.values_at("http-code", "error")
    assert_equal [ 404, 0 ], [ stat("out").status, control("GET", "ready").json.dig("state", "file_migrations") ]

    migration, = extraction("in/root.zip", nil)
    assert_equal [ "completed", "", 2 ], migration.values_at("status", "dest_path", "files_moved")
    assert_equal [ "top", "\x00\xFF".b, "directory" ], [ download("top.txt").body, download("nested/deep.bin").body.b, stat("nested").json["type"] ]
    again, = extraction("in/root.zip", "")
    assert_equal [ "failed", "The destination exists." ], again.values_at("status", "failure_message")
    assert_equal [ [ 201, 1, false ], [ 201, 2, false ] ], journaled("files.unzip", %w[status migration destination_created]).last(2)
  end

  # Each refusal is Files.com's failure message, and the migration changes nothing.
  def test_unzip_fails_an_unsafe_missing_or_conflicting_extraction_without_any_change
    upload("in/unsafe.zip", [ zip([ [ "ok.txt", "ok" ], [ "../escape.txt", "no" ] ]) ])
    upload("in/good.zip", [ zip([ [ "one.txt", "1" ], [ "two.txt", "2" ] ]) ])
    upload("out/one.txt", [ "old" ])
    {
      [ "in/unsafe.zip", {} ] => "Invalid ZIP entry path: ../escape.txt",
      [ "in/good.zip", {} ] => "The destination exists.",
      [ "in/good.zip", { "filename" => "three.txt" } ] => "File not found inside ZIP: three.txt",
    }.each_with_index do |((zip, params), message), index|
      assert_equal 201, api("POST", "/file_actions/unzip", { "path" => zip, "destination" => "out" }.merge(params)).status
      2.times { @failed = api("GET", "/file_migrations/#{index + 1}").json }
      assert_equal [ "failed", message ], @failed.values_at("status", "failure_message")
    end
    assert_equal [ 404, 404, "old" ], [ stat("out/ok.txt").status, stat("out/two.txt").status, download("out/one.txt").body ]

    assert_equal 201, api("POST", "/file_actions/unzip", { "path" => "in/good.zip", "destination" => "out", "filename" => "two.txt" }).status
    assert_equal 201, api("POST", "/file_actions/unzip", { "path" => "in/good.zip", "destination" => "out", "overwrite" => true }).status
    [ 4, 4, 5, 5 ].each { |id| api("GET", "/file_migrations/#{id}") }
    assert_equal [ "1", "2" ], [ download("out/one.txt").body, download("out/two.txt").body ]
  end

  def test_zip_list_and_unzip_answer_files_com_errors_for_folders_missing_files_and_unreadable_archives
    upload("folder/inside.bin", [ "x" ])
    upload("plain.txt", [ "not a zip" ])
    upload("encrypted.zip", [ zip([ [ "secret.txt", "s", { flags: 1 } ] ]) ])
    upload("bzip2.zip", [ zip([ [ "packed.txt", "p", { method: 12 } ] ]) ])
    upload("cp437.zip", [ zip([ [ "caf\x82.txt".b, "c" ] ]) ])
    {
      "folder" => [ 422, "bad-request/folders-not-allowed" ], "missing.zip" => [ 404, "not-found" ], "plain.txt" => [ 422, "processing-failure/invalid-zip-file" ],
      "encrypted.zip" => [ 422, "processing-failure/invalid-zip-file" ], "cp437.zip" => [ 501, "simulation/not-supported" ],
    }.each do |path, expected|
      listed = api("GET", "/file_actions/zip_list/#{route(path)}")
      assert_equal expected, [ listed.status, listed.json["type"] ], path
    end
    # Listing reads only the directory; the compression method matters when an entry is extracted.
    assert_equal([ [ "packed.txt", 1 ] ], api("GET", "/file_actions/zip_list/bzip2.zip").json.map { |entry| entry.values_at("path", "size") })

    folder = api("POST", "/file_actions/unzip", { "path" => "folder", "destination" => "out" })
    assert_equal [ 422, "bad-request/folders-not-allowed", 404 ], [ folder.status, folder.json["type"], stat("out").status ]
    # A path or destination left out fails the API's parameter validation, a bare bad-request.
    { { "path" => "plain.txt" } => "destination is missing", { "destination" => "out" } => "path is missing" }.each do |params, message|
      assert_equal [ 422, "bad-request", message ], api("POST", "/file_actions/unzip", params).json.values_at("http-code", "type", "error"), params.inspect
    end
    spaced = api("POST", "/file_actions/unzip", { "path" => "encrypted.zip", "destination" => "out /x" })
    assert_equal [ 422, "bad-request/path-cannot-have-trailing-whitespace", 404 ], [ spaced.status, spaced.json["type"], stat("out ").status ]
    { "plain.txt" => "Unable to list contents of the .zip file. Does it exist and is it a valid ZIP archive?",
      "bzip2.zip" => "zip_extract: unsupported compression method 12 (only STORED=0 and DEFLATE=8 are supported)" }.each do |zip, message|
      id = api("POST", "/file_actions/unzip", { "path" => zip, "destination" => "out" }).json["file_migration_id"]
      2.times { @failed = api("GET", "/file_migrations/#{id}").json }
      assert_equal [ "failed", message ], @failed.values_at("status", "failure_message"), zip
    end
    assert_equal [], api("GET", "/folders/out").json
  end

  # An extraction is admitted against the byte and record limits by the entries' recorded sizes
  # before any entry is expanded, and no entry's data grows past its recorded size, so a small
  # archive of highly compressible data cannot make the simulator expand more than its limits allow.
  # `expanded` is what the actual archives produced while the migrations were applied.
  def test_unzip_expands_nothing_past_its_admitted_recorded_sizes
    @app = new_app(max_transfer_bytes: 4096)
    upload("over.zip", [ zip([ [ "zeros.bin", "\0" * 65_536, { method: 8 } ] ]) ])
    upload("claims.zip", [ zip([ [ "small.txt", "tiny", { method: 8, size: 60_000 } ] ]) ])
    upload("longer.zip", [ zip([ [ "ok.txt", "ok" ], [ "zeros.bin", "\0" * 65_536, { method: 8, size: 10 } ] ]) ])
    upload("fits.zip", [ zip([ [ "a.bin", "a" * 1500, { method: 8 } ], [ "b.txt", "b" * 500 ] ]) ])
    zips = %w[over claims longer fits].to_h { |name| [ name, download("#{name}.zip").body.bytesize ] }
    assert_operator zips["over"], :<, 300
    in_use = zips.values.sum
    assert_equal in_use, bytes_in_use

    {
      "over" => [ "Extracting 65536 bytes would pass the transfer limit of 4096 bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{in_use} are in use", 0 ],
      "claims" => [ "Extracting 60000 bytes would pass the transfer limit of 4096 bytes (FILES_MOCK_MAX_TRANSFER_BYTES); #{in_use} are in use", 0 ],
      "longer" => [ "An entry whose data does not match its recorded size (zeros.bin) is not simulated", 2..(2 + 16_384) ],
    }.each do |name, (message, expanded)|
      failed, archives = extraction("#{name}.zip", "out/#{name}")
      assert_equal [ "failed", message ], failed.values_at("status", "failure_message"), name
      assert_operator expanded, :===, archives.sum(&:expanded), name
      assert_equal 404, stat("out/#{name}/ok.txt").status, name
    end
    assert_equal in_use, bytes_in_use

    completed, archives = extraction("fits.zip", "out/fits")
    assert_equal [ "completed", 2, 0 ], completed.values_at("status", "files_moved", "files_total")
    assert_equal 2000, archives.sum(&:expanded)
    assert_equal [ "a" * 1500, "b" * 500 ], [ download("out/fits/a.bin").body, download("out/fits/b.txt").body ]
    assert_equal in_use + 2000, bytes_in_use
  end

  # file_actions/zip saves a ZIP of its selection as its destination once its FileMigration
  # completes: a selected file by its own name, each file in a selected folder, at any depth, by the
  # folder's name and its path inside it; no folder entries, so an empty folder is left out and an
  # empty file kept. The destination's parents are created with the request. The migration's path is
  # the first requested path (here in/docs, not the lexically first in/a/file.txt), files_moved is 0
  # until it completes and then counts the one saved archive, and files_total is always 0. The saved
  # archive lists and extracts as any ZIP file does. Entry order is not a contract, so entries are
  # compared as sets; the entry count is journaled.
  def test_zip_saves_its_selection_as_named_entries_once_its_migration_completes
    binary = (0...4096).map { |index| (index * 31) % 256 }.pack("C*")
    upload("in/a/file.txt", [ "hello" ])
    upload("in/docs/report.bin", [ binary ])
    upload("in/docs/empty.txt", [ "" ])
    upload("in/docs/sub/deep/é +.txt", [ "unicode" ])
    assert_equal 201, api("POST", "/folders/#{route("in/docs/empty-folder/inner")}").status
    assert_equal true, control("GET", "ready").json.dig("transfers", "zip", "zip_creation")

    started = zip_action([ "in/docs", "in/a/file.txt", "in/docs" ], "out/new/archive.zip")
    assert_equal [ 201, { "status" => "pending", "file_migration_id" => 1 } ], [ started.status, started.json ]
    assert_equal [ "directory", 404 ], [ stat("out/new").json["type"], stat("out/new/archive.zip").status ]
    processing = { "id" => 1, "path" => "in/docs", "dest_path" => "out/new/archive.zip", "operation" => "zip", "status" => "processing", "files_moved" => 0, "files_total" => 0 }
    assert_equal processing, api("GET", "/file_migrations/1").json
    assert_equal processing.merge("status" => "completed", "files_moved" => 1), api("GET", "/file_migrations/1").json

    listed = api("GET", "/file_actions/zip_list/#{route("out/new/archive.zip")}").json.map { |entry| entry.values_at("path", "size") }
    assert_equal [ [ "docs/empty.txt", 0 ], [ "docs/report.bin", 4096 ], [ "docs/sub/deep/é +.txt", 7 ], [ "file.txt", 5 ] ], listed.sort
    assert_equal 201, api("POST", "/file_actions/unzip", { "path" => "out/new/archive.zip", "destination" => "x" }).status
    2.times { api("GET", "/file_migrations/2") }
    assert_equal [ "hello", binary, "", "unicode" ], [ download("x/file.txt").body, download("x/docs/report.bin").body.b, download("x/docs/empty.txt").body, download("x/docs/sub/deep/é +.txt").body.force_encoding("UTF-8") ]
    assert_equal 404, stat("x/docs/empty-folder").status
    assert_equal [ [ 201, 1, 2, 2 ] ], journaled("files.zip", %w[status migration selected parents_created])
    assert_equal [ [ "completed", 1, 4, false ] ], journaled("file_migrations.find", %w[migration_status files entries replaced]).take(2).drop(1)
  end

  # Repeated entry names are numbered as files-protocol-server's ZIP stream numbers them, counting
  # every name the archive has used so far, across the whole selection in its sorted order:
  # "f (1).txt" for an extension, "README (1)" for none, and "f (1) (1).txt" for a later file named
  # like an earlier generated one. A repeat the stream cannot number, or numbering that repeats a name,
  # fails the migration as not simulated, and nothing is saved.
  def test_zip_numbers_repeated_entry_names_across_the_whole_archive_as_files_com_does
    paths = [ "p/a/f.txt", "q/a/f.txt", "r/f.txt", "s/f.txt", "t/f (1).txt", "u/README", "v/README", "w/v1.2.txt", "x/v1.2.txt" ]
    paths.each { |path| upload(path, [ path ]) }
    selection = [ "x/v1.2.txt", "q/a", "p/a", "r/f.txt", "s/f.txt", "t/f (1).txt", "v/README", "u/README", "w/v1.2.txt" ]
    assert_equal [ "completed", "x/v1.2.txt", 1 ], zip_created(selection, "out.zip").values_at("status", "path", "files_moved")
    expected = { "a/f.txt" => "p/a/f.txt", "a/f (1).txt" => "q/a/f.txt", "f.txt" => "r/f.txt", "f (1).txt" => "s/f.txt", "f (1) (1).txt" => "t/f (1).txt",
                 "README" => "u/README", "README (1)" => "v/README", "v1.2.txt" => "w/v1.2.txt", "v1.2 (1).txt" => "x/v1.2.txt" }
    assert_equal expected.keys.sort, api("GET", "/file_actions/zip_list/out.zip").json.map { |entry| entry["path"] }.sort
    assert_equal 201, api("POST", "/file_actions/unzip", { "path" => "out.zip", "destination" => "extracted" }).status
    2.times { api("GET", "/file_migrations/2") }
    assert_equal(expected, expected.to_h { |name, _| [ name, download("extracted/#{name}").body ] })

    upload("h1/.env", [ "1" ])
    upload("h2/.env", [ "2" ])
    upload("c1/g (1).txt", [ "1" ])
    upload("c2/g.txt", [ "2" ])
    upload("c3/g.txt", [ "3" ])
    { [ "h1/.env", "h2/.env" ] => "A repeated ZIP entry name that Files.com's ZIP stream cannot number (.env) is not simulated",
      [ "c1/g (1).txt", "c2/g.txt", "c3/g.txt" ] => "A ZIP in which Files.com's entry numbering repeats the name g (1).txt is not simulated" }.each do |selection_, message|
      assert_equal [ "failed", message, 0 ], zip_created(selection_, "refused.zip").values_at("status", "failure_message", "files_moved"), message
      assert_equal 404, stat("refused.zip").status
    end
  end

  # The destination and the selection are read when the migration runs, as in Rails'
  # FileMigration#perform_zip: a request is accepted whatever is there; an existing file then fails
  # the migration unless overwrite is true, and a file saved there after the request counts too.
  # With overwrite, Rails deletes the old file before its ZIP stream starts, so that old file is not
  # part of the new archive, even inside a selected folder. Separately, the simulator chooses its
  # entries before it saves the new archive, so a new destination inside a selected folder is not an
  # entry either; the sources do not establish when Files.com's upload makes a new destination
  # visible, so that case checks the simulator only, not parity. A selected file's current bytes are
  # used, and a missing destination parent is created again. Selecting the overwritten destination
  # itself, a folder destination and a selected path that is gone are refused as not simulated.
  def test_zip_decides_an_existing_destination_when_its_migration_runs
    upload("in/a.txt", [ "a" ])
    upload("out/old.zip", [ "old" ])
    assert_equal [ "failed", "The destination exists." ], zip_created([ "in/a.txt" ], "out/old.zip").values_at("status", "failure_message")
    assert_equal "old", download("out/old.zip").body

    later = zip_action([ "in/a.txt" ], "out/later.zip").json["file_migration_id"]
    upload("out/later.zip", [ "later" ])
    2.times { @later = api("GET", "/file_migrations/#{later}").json }
    assert_equal [ "failed", "The destination exists." ], @later.values_at("status", "failure_message")
    assert_equal "later", download("out/later.zip").body

    assert_equal "completed", zip_created([ "in/a.txt" ], "out/old.zip", "overwrite" => true)["status"]
    assert_equal([ [ "a.txt", 1 ] ], api("GET", "/file_actions/zip_list/#{route("out/old.zip")}").json.map { |entry| entry.values_at("path", "size") })

    upload("dir/input.txt", [ "input" ])
    upload("dir/out.zip", [ "old archive" ])
    assert_equal [ "completed", 1 ], zip_created([ "dir" ], "dir/out.zip", "overwrite" => true).values_at("status", "files_moved")
    assert_equal([ [ "dir/input.txt", 5 ] ], api("GET", "/file_actions/zip_list/#{route("dir/out.zip")}").json.map { |entry| entry.values_at("path", "size") })
    extracting = api("POST", "/file_actions/unzip", { "path" => "dir/out.zip", "destination" => "dir-extracted" }).json["file_migration_id"]
    2.times { api("GET", "/file_migrations/#{extracting}") }
    assert_equal [ "input", 404 ], [ download("dir-extracted/dir/input.txt").body, stat("dir-extracted/dir/out.zip").status ]
    assert_equal "A ZIP that selects the file it overwrites (dir/out.zip) is not simulated", zip_created([ "dir/out.zip" ], "dir/out.zip", "overwrite" => true)["failure_message"]
    assert_equal([ [ "dir/input.txt", 5 ] ], api("GET", "/file_actions/zip_list/#{route("dir/out.zip")}").json.map { |entry| entry.values_at("path", "size") })
    archived = download("dir/out.zip").body.bytesize
    assert_equal "completed", zip_created([ "dir" ], "dir/sub/new.zip")["status"]
    listed = api("GET", "/file_actions/zip_list/#{route("dir/sub/new.zip")}").json.map { |entry| entry.values_at("path", "size") }
    assert_equal [ [ "dir/input.txt", 5 ], [ "dir/out.zip", archived ] ], listed.sort

    current = zip_action([ "in/a.txt" ], "made/later/current.zip").json["file_migration_id"]
    upload("in/a.txt", [ "newer" ])
    assert_equal 204, api("DELETE", "/files/#{route("made/later")}").status
    2.times { @current = api("GET", "/file_migrations/#{current}").json }
    assert_equal "completed", @current["status"]
    assert_equal([ [ "a.txt", 5 ] ], api("GET", "/file_actions/zip_list/#{route("made/later/current.zip")}").json.map { |entry| entry.values_at("path", "size") })

    assert_equal 201, api("POST", "/folders/#{route("out/folder.zip")}").status
    assert_equal "The destination exists.", zip_created([ "in/a.txt" ], "out/folder.zip")["failure_message"]
    assert_equal "Replacing the folder out/folder.zip with a ZIP is not simulated", zip_created([ "in/a.txt" ], "out/folder.zip", "overwrite" => true)["failure_message"]

    gone = zip_action([ "in/a.txt" ], "out/gone.zip").json["file_migration_id"]
    assert_equal 204, api("DELETE", "/files/#{route("in/a.txt")}").status
    2.times { @gone = api("GET", "/file_migrations/#{gone}").json }
    assert_equal [ "failed", "A ZIP whose selected path in/a.txt no longer exists when it is made is not simulated" ], @gone.values_at("status", "failure_message")
    assert_equal 404, stat("out/gone.zip").status
  end

  # The controller's order decides what a refusal leaves: missing or invalid parameters, a missing
  # selected path (checked before the destination), a path in another spelling, a destination
  # inside a file and a destination folder name ending in whitespace are refused before anything is
  # made, as is a request a fault fails. A selection whose folders hold no file is refused by
  # ZipDownload's validation after the destination's missing parents were created: they stay, and
  # no migration is made. A destination whose last name ends in whitespace, or whose folder name has
  # an inner space, is not refused by that rule. A selection holding an empty folder beside a file is
  # accepted, and the folder adds nothing.
  def test_zip_refuses_invalid_requests_before_any_change_and_keeps_new_parents_for_a_file_less_selection
    upload("in/a.txt", [ "a" ])
    assert_equal 201, api("POST", "/folders/#{route("in/empty/inner")}").status
    {
      {} => [ 422, "bad-request" ],
      { "paths" => [], "destination" => "out/z.zip" } => [ 422, "bad-request/request-params-required" ],
      { "paths" => nil, "destination" => "out/z.zip" } => [ 422, "bad-request/request-params-required" ],
      { "paths" => "", "destination" => "out/z.zip" } => [ 422, "bad-request/request-params-required" ],
      { "paths" => [ "in/a.txt" ] } => [ 422, "bad-request" ],
      { "paths" => "in/a.txt", "destination" => "out/z.zip" } => [ 422, "bad-request" ],
      { "paths" => [ "in/missing.txt" ], "destination" => "out/z.zip" } => [ 404, "not-found" ],
      { "paths" => [ "in/missing.txt" ], "destination" => "safeplace /archive.zip" } => [ 404, "not-found" ],
      { "paths" => [ "in/missing.txt" ], "destination" => nil } => [ 404, "not-found" ],
      { "paths" => [ "in/empty" ], "destination" => "" } => [ 422, "processing-failure/model-save-error" ],
      { "paths" => [ "in/a.txt" ], "destination" => nil } => [ 500, nil ],
      { "paths" => [ "in/a.txt" ], "destination" => "", "overwrite" => true } => [ 500, nil ],
      { "paths" => [ "in/a.txt" ], "destination" => "safeplace /archive.zip" } => [ 422, "bad-request/path-cannot-have-trailing-whitespace" ],
      { "paths" => [ "in/a.txt/" ], "destination" => "out/z.zip" } => [ 501, "simulation/not-supported" ],
      { "paths" => [ "in/a.txt" ], "destination" => "in/a.txt/z.zip" } => [ 422, "bad-request/folder-must-not-be-a-file" ],
    }.each do |params, expected|
      refused = api("POST", "/file_actions/zip", params)
      assert_equal expected, [ refused.status, refused.json["type"] ], params.inspect
    end
    add_fault({ "operation" => "files.zip", "match" => { "destination" => "out/f.zip" }, "status" => 503 })
    assert_equal 503, zip_action([ "in/a.txt" ], "out/f.zip").status
    assert_equal [ 404, 404, 0 ], [ stat("out").status, stat("safeplace ").status, control("GET", "ready").json.dig("state", "file_migrations") ]

    file_less = zip_action([ "in/empty" ], "out/new/archive.zip")
    assert_equal [ 422, "processing-failure/model-save-error" ], [ file_less.status, file_less.json["type"] ]
    assert_equal [ "directory", "directory", 404, 0 ], [ stat("out").json["type"], stat("out/new").json["type"], stat("out/new/archive.zip").status,
                                                         control("GET", "ready").json.dig("state", "file_migrations") ]

    assert_equal "completed", zip_created([ "in/a.txt" ], "safe place/archive.zip ")["status"]
    assert_equal([ [ "a.txt", 1 ] ], api("GET", "/file_actions/zip_list/#{route("safe place/archive.zip ")}").json.map { |entry| entry.values_at("path", "size") })
    assert_equal "completed", zip_created([ "in/empty", "in/a.txt" ], "out/mixed.zip")["status"]
    assert_equal([ [ "a.txt", 1 ] ], api("GET", "/file_actions/zip_list/#{route("out/mixed.zip")}").json.map { |entry| entry.values_at("path", "size") })
  end

  # A ZIP is admitted by the most bytes it can take (its files' sizes and its headers) before it is
  # built, and by one more record; a request whose parent folders would pass the record limit is
  # refused at once. Nothing is saved or created for a refused one.
  def test_zip_stays_within_the_transfer_and_record_limits
    @app = new_app(max_transfer_bytes: 4096)
    upload("in/zeros.bin", [ "\0" * 3000 ])
    failed = zip_created([ "in/zeros.bin" ], "out/zeros.zip")
    assert_equal [ "failed", "A ZIP of up to 3116 bytes would pass the transfer limit of 4096 bytes (FILES_MOCK_MAX_TRANSFER_BYTES); 3000 are in use" ], failed.values_at("status", "failure_message")
    assert_equal [ 404, 3000 ], [ stat("out/zeros.zip").status, bytes_in_use ]

    @app = new_app(max_records: 3)
    upload("a.txt", [ "a" ])
    refused = zip_action([ "a.txt" ], "o/p/q/z.zip")
    assert_equal [ 409, "simulation/limit-exceeded", 404 ], [ refused.status, refused.json["type"], stat("o").status ]
    failed = zip_created([ "a.txt" ], "o/p/z.zip")
    assert_equal [ "failed", "The simulator already holds 3 files and folders (FILES_MOCK_MAX_RECORDS)" ], failed.values_at("status", "failure_message")
    assert_equal 404, stat("o/p/z.zip").status
  end

  private

  def zip_action(paths, destination, params = {})
    api("POST", "/file_actions/zip", { "paths" => paths, "destination" => destination }.merge(params))
  end

  # Requests a ZIP and polls its FileMigration to its end, returning the migration.
  def zip_created(paths, destination, params = {})
    started = zip_action(paths, destination, params)
    assert_equal 201, started.status, started.body
    2.times.map { api("GET", "/file_migrations/#{started.json["file_migration_id"]}").json }.last
  end

  # Starts an unzip into destination, polls its FileMigration until it is applied, and returns the
  # migration with every ZipArchive the simulator read meanwhile.
  def extraction(zip, destination)
    archives = []
    tracer = TracePoint.new(:return) { |point| archives << point.self if point.method_id == :initialize && point.self.is_a?(FilesMockServer::Simulation::ZipArchive) }
    started = api("POST", "/file_actions/unzip", { "path" => zip, "destination" => destination })
    assert_equal 201, started.status, started.body
    migration = tracer.enable { 2.times.map { api("GET", "/file_migrations/#{started.json["file_migration_id"]}").json }.last }
    [ migration, archives ]
  end

  # A ZIP archive as a ZIP tool writes one: each entry's local header and data, then the central
  # directory and its end record. Each entry is [ name, bytes, { method:, flags:, size: } ]; a non-ASCII
  # name is marked UTF-8 unless flags say otherwise, method 8 deflates and any other method keeps the
  # bytes as they are, and size records another uncompressed size than the bytes have.
  def zip(entries)
    body = +"".b
    directory = +"".b
    entries.each do |name, bytes, options = {}|
      method = options.fetch(:method, 0)
      flags = options.fetch(:flags, name.b.ascii_only? || name.encoding == Encoding::BINARY ? 0 : 0x800)
      data = method == 8 ? Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS).deflate(bytes, Zlib::FINISH) : bytes.b
      raw = name.b
      crc = Zlib.crc32(bytes)
      offset = body.bytesize
      size = options.fetch(:size, bytes.bytesize)
      body << [ 0x04034b50, 20, flags, method, 0, 0, crc, data.bytesize, size, raw.bytesize, 0 ].pack("VvvvvvVVVvv") << raw << data
      directory << [ 0x02014b50, 20, 20, flags, method, 0, 0, crc, data.bytesize, size, raw.bytesize, 0, 0, 0, 0, 0, offset ].pack("VvvvvvvVVVvvvvvVV") << raw
    end
    body + directory + [ 0x06054b50, 0, 0, entries.size, entries.size, directory.bytesize, body.bytesize, 0 ].pack("VvvvvVVv")
  end

  def action(name, path, destination, params = {}, to: app)
    api("POST", "/file_actions/#{name}/#{route(path)}", { "destination" => destination }.merge(params), to:)
  end

  def stat(path, to: app)
    api("GET", "/files/#{route(path)}", { "action" => "stat" }, to:)
  end

  def bytes_in_use
    control("GET", "ready").json.dig("transfers", "state", "bytes_in_use")
  end

  def control_reset(body)
    response = control("POST", "reset", body)
    assert_equal 200, response.status, response.body
    response.json
  end
end
