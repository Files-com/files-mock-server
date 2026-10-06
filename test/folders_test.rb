require_relative "test_helper"

class FoldersTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  def setup
    @app = new_app
  end

  # The requests the .NET SDK sends for an owned folder's lifecycle: an exclusive create, stat with
  # action=stat (root, folder and files), a listing one item per page, deletes with recursive=False
  # in the query string, and a lookup of each deleted path.
  def test_a_folder_is_created_listed_and_deleted_without_recursion
    created = api("POST", "/folders/owned", { "mkdir_parents" => false, "path" => "owned", "provided_mtime" => "2026-09-24 00:00:00Z" })
    assert_equal [ 201, "owned", "owned", "directory", "2026-09-24T00:00:00Z" ], [ created.status, *created.json.values_at("path", "display_name", "type", "provided_mtime") ]
    refute created.json.key?("size")
    again = api("POST", "/folders/owned", { "mkdir_parents" => false })
    assert_equal [ 422, "processing-failure/destination-exists" ], [ again.status, again.json["type"] ]

    root = stat("/")
    assert_equal [ 200, "", "directory" ], [ root.status, *root.json.values_at("path", "type") ]
    assert_equal([ 404, "not-found" ], stat("owned/missing.bin").then { |response| [ response.status, response.json["type"] ] })
    %w[short-read.bin binary.bin empty.bin].each { |name| assert_equal 201, upload("owned/#{name}", [ name ]).status }
    assert_equal [ "owned/binary.bin", "file", 10 ], stat("owned/binary.bin").json.values_at("path", "type", "size")
    refute stat("owned/binary.bin").json.key?("download_uri")

    assert_equal [ [ "owned/binary.bin" ], [ "owned/empty.bin" ], [ "owned/short-read.bin" ] ], pages("owned", 1)
    refused = delete("owned")
    assert_equal [ 422, "processing-failure/folder-not-empty" ], [ refused.status, refused.json["type"] ]

    %w[binary.bin empty.bin short-read.bin].each do |name|
      assert_equal([ 204, "" ], delete("owned/#{name}").then { |response| [ response.status, response.body ] })
      assert_equal 404, stat("owned/#{name}").status
    end
    # A folder is a record of its own: deleting its last file leaves it in place, empty.
    assert_equal [ 200, "directory", [] ], [ stat("owned").status, stat("owned").json["type"], pages("owned", 1).flatten ]
    assert_equal 204, delete("owned").status
    assert_equal [ 404, 404 ], [ stat("owned").status, delete("owned").status ]
    assert_equal([ 422, "processing-failure/folder-not-empty" ], delete("/").then { |response| [ response.status, response.json["type"] ] })
    assert_equal([ [ "file", 204 ], [ "file", 204 ], [ "file", 204 ], [ "directory", 204 ] ], journaled("files.delete", %w[type status]).select { |_, status| status == 204 })
  end

  # The Ruby SDK's lookup of a missing file after Files.language = "es" (Accept-Language: es) gets the
  # answer a Files.com site sent in Spanish. Nothing else is translated: the same lookup in any other
  # language, other operations' not-found answers and an existing path keep their usual answers.
  def test_a_missing_file_lookup_is_answered_in_spanish_only_when_spanish_is_asked_for
    assert_equal 201, api("POST", "/folders/owned", {}).status
    lookup = ->(path, language) { request(app, "GET", "/api/rest/v1/file_actions/metadata/#{path}", nil, language ? { "HTTP_ACCEPT_LANGUAGE" => language } : {}) }
    spanish = lookup.call("owned/read.txt", "es")
    assert_equal [ 404, "application/json", "not-found", { "error" => "No se ha encontrado. Esto puede estar relacionado con tus permisos.", "http-code" => 404, "title" => "Not Found", "type" => "not-found" } ],
                 [ spanish.status, spanish.headers["content-type"], spanish.headers["x-files-error-class"], spanish.json ]

    english = { "error" => "Not Found.  This may be related to your permissions.", "http-code" => 404, "title" => "Not Found", "type" => "not-found" }
    [ nil, "en", "es-ES", "fr" ].each { |language| assert_equal [ 404, english ], lookup.call("owned/read.txt", language).then { |response| [ response.status, response.json ] }, language.inspect }
    spanish_request = { "HTTP_ACCEPT_LANGUAGE" => "es" }
    assert_equal([ 404, english ], request(app, "GET", "/api/rest/v1/files/owned/read.txt?action=stat", nil, spanish_request).then { |response| [ response.status, response.json ] })
    assert_equal([ 404, english ], request(app, "GET", "/api/rest/v1/folders/missing", nil, spanish_request).then { |response| [ response.status, response.json ] })
    assert_equal([ 200, "owned" ], lookup.call("owned", "es").then { |response| [ response.status, response.json["path"] ] })
  end

  # Writes create their missing parent folders even when mkdir_parents is false, as on a site that
  # always creates parent folders; the simulator advertises that policy rather than guess a site's.
  def test_writes_create_missing_parent_folders_under_the_advertised_site_policy
    assert_equal({ "always_mkdir_parents" => true }, control("GET", "ready").json.dig("namespace", "site_policy"))
    assert_equal 201, api("POST", "/folders/a/b", { "mkdir_parents" => false }).status
    assert_equal 201, upload("x/y/z.bin", [ "z" ], finalize: { "mkdir_parents" => false }).status
    assert_equal(%w[directory directory directory directory], %w[a a/b x x/y].map { |path| stat(path).json["type"] })
    assert_equal [ [ "a" ], [ "x" ] ], pages("/", 1)
  end

  # Nothing adopts or overwrites a name another kind of entry holds, and a refusal changes nothing.
  def test_files_and_folders_never_take_each_others_names
    upload("taken.bin", [ "file" ])
    api("POST", "/folders/taken", {})
    pending = begin_upload("later")
    put_part(pending, "bytes")
    api("POST", "/folders/later", {})
    held = control("GET", "ready").json["namespace"]["state"]
    {
      "a folder where a file is" => [ api("POST", "/folders/taken.bin", {}), 422, "processing-failure/destination-exists" ],
      "a file finalized where a folder is" => [ api("POST", "/files/later", { "action" => "end", "ref" => pending["ref"], "size" => 5 }), 422, "processing-failure/destination-exists" ],
      "an upload begun where a folder is" => [ api("POST", "/file_actions/begin_upload/taken", {}), 501, "simulation/not-supported" ],
      "a folder inside a file" => [ api("POST", "/folders/taken.bin/inner", {}), 422, "bad-request/folder-must-not-be-a-file" ],
      "a folder two levels inside a file" => [ api("POST", "/folders/taken.bin/inner/deeper", {}), 501, "simulation/not-supported" ],
      "another spelling of a folder" => [ api("POST", "/folders/TAKEN", {}), 501, "simulation/not-supported" ],
      "another spelling of a file's folder" => [ api("POST", "/file_actions/begin_upload/Taken/child.bin", {}), 501, "simulation/not-supported" ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
    end
    assert_equal held, control("GET", "ready").json["namespace"]["state"]
    assert_equal([ "file", "directory", "directory" ], %w[taken.bin taken later].map { |path| stat(path).json["type"] })
  end

  # On the folders endpoints the API's path helper checks every name of the path, the folder's own
  # included, for trailing whitespace, then the path for a zero-width space; a refusal creates nothing.
  # On a file route the last name is the file's own, which may end in whitespace.
  def test_folder_endpoints_refuse_any_name_ending_in_whitespace_and_zero_width_spaces
    api("POST", "/folders/kept", {})
    held = control("GET", "ready").json["namespace"]["state"]
    { "bad-request/path-cannot-have-trailing-whitespace" => [ "new ", "a /b", "kept/b\t" ], "bad-request/invalid-path" => [ "zero\u200Bwidth", "kept/\u200B" ] }.each do |type, paths|
      paths.each do |path|
        [ api("POST", "/folders/#{route(path)}", {}), api("GET", "/folders/#{route(path)}") ].each do |refused|
          assert_equal [ 422, type, type ], [ refused.status, refused.json["type"], refused.headers["x-files-error-class"] ], path.inspect
        end
      end
    end
    assert_equal held, control("GET", "ready").json["namespace"]["state"]
    mistyped = api("POST", "/folders/#{route("new ")}", { "mkdir_parents" => "maybe" })
    assert_equal [ 422, "bad-request", "mkdir_parents is invalid" ], mistyped.json.values_at("http-code", "type", "error")

    assert_equal [ 201, 201, 422 ], [ upload("new ", [ "file" ]).status, upload("kept/b\t", [ "file" ]).status, begin_upload_status("a /b") ]
    assert_equal(%w[file file], [ "new ", "kept/b\t" ].map { |path| stat(path).json["type"] })
  end

  def test_listing_cursors_are_scoped_to_their_simulator_epoch_folder_and_page_size
    %w[a/1.bin a/2.bin a/3.bin b/1.bin].each { |path| upload(path, [ path ]) }
    first = api("GET", "/folders/a", { "per_page" => 1 })
    cursor = first.headers["x-files-cursor"]
    assert_equal cursor, first.headers["x-files-cursor-next"]
    other = new_app
    api("POST", "/folders/a", {}, to: other)
    rejected = {
      "another folder" => api("GET", "/folders/b", { "per_page" => 1, "cursor" => cursor }),
      "another page size" => api("GET", "/folders/a", { "per_page" => 2, "cursor" => cursor }),
      "malformed" => api("GET", "/folders/a", { "per_page" => 1, "cursor" => "not-a-cursor" }),
      "another simulator" => api("GET", "/folders/a", { "per_page" => 1, "cursor" => cursor }, to: other),
    }
    rejected.each { |name, response| assert_equal [ 422, "bad-request/invalid-cursor" ], [ response.status, response.json["type"] ], name }

    # A cursor continues after its last entry: an entry added after that point appears once, and one deleted before it is reached is skipped.
    upload("a/0.bin", [ "before the cursor" ])
    upload("a/4.bin", [ "after the cursor" ])
    delete("a/2.bin")
    rest = api("GET", "/folders/a", { "per_page" => 1, "cursor" => cursor })
    assert_equal([ "a/3.bin" ], rest.json.map { |entry| entry["path"] })
    assert_equal([ "a/4.bin" ], api("GET", "/folders/a", { "per_page" => 1, "cursor" => rest.headers["x-files-cursor"] }).json.map { |entry| entry["path"] })
    reset
    api("POST", "/folders/a", {})
    assert_equal([ 422, "bad-request/invalid-cursor" ], api("GET", "/folders/a", { "per_page" => 1, "cursor" => cursor }).then { |response| [ response.status, response.json["type"] ] })
  end

  # Each page's journal entry has the SHA-256 of the cursor it received and of the one it returned,
  # so a test can check that a client sent back exactly the cursor it was given.
  def test_the_journal_follows_each_listing_page_to_the_cursor_it_was_sent
    %w[c.bin a.bin b.bin].each { |name| upload("f/#{name}", [ name ]) }
    assert_equal [ [ "f/a.bin" ], [ "f/b.bin" ], [ "f/c.bin" ] ], pages("f", 1)
    listed = journaled("folders.list", %w[items cursor_sha256 next_cursor_sha256])
    assert_equal [ 1, 1, 1 ], listed.map(&:first)
    assert_nil listed.first[1]
    assert_nil listed.last[2]
    assert_equal(listed.first(2).map(&:last), listed.drop(1).map { |entry| entry[1] })
  end

  def test_listing_and_deletes_refuse_what_is_not_simulated_or_out_of_bounds
    upload("f/file.bin", [ "x" ])
    {
      "per_page 0" => [ api("GET", "/folders/f", { "per_page" => 0 }), 422, "bad-request/request-params-invalid" ],
      "per_page over the maximum" => [ api("GET", "/folders/f", { "per_page" => 10_001 }), 422, "bad-request/request-params-invalid" ],
      "sorting" => [ api("GET", "/folders/f", { "sort_by" => { "path" => "desc" } }), 501, "simulation/not-supported" ],
      "searching" => [ api("GET", "/folders/f", { "search" => "file" }), 501, "simulation/not-supported" ],
      "a missing folder" => [ api("GET", "/folders/missing"), 404, "not-found" ],
      "a file's path" => [ api("GET", "/folders/f/file.bin"), 501, "simulation/not-supported" ],
      "a recursive delete of the root" => [ api("DELETE", "/files/%2F", { "recursive" => "True" }), 501, "simulation/not-supported" ],
      "an unreadable recursive" => [ api("DELETE", "/files/f", { "recursive" => "maybe" }), 422, "bad-request" ],
      "a download of a folder" => [ api("GET", "/files/f"), 422, "bad-request/cannot-download-directory" ],
      "a redirect" => [ api("GET", "/files/f/file.bin", { "action" => "redirect" }), 501, "simulation/not-supported" ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
    end
    assert_equal [ 204, 204 ], [ delete("f/file.bin").status, api("DELETE", "/files/f", { "recursive" => "false" }).status ]
  end

  # Files and folders share FILES_MOCK_MAX_RECORDS. A write that would pass it creates none of the
  # folders it needs, and an upload that cannot be published stays open.
  def test_files_and_folders_share_the_record_limit_without_partial_writes
    simulator = new_app(max_records: 2)
    part = begin_upload("a/b.bin", to: simulator)
    etag = transfer("PUT", part["upload_uri"], "bytes", to: simulator).headers["etag"].delete('"')
    refused = api("POST", "/folders/c/d", {}, to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ refused.status, refused.json["type"] ]
    assert_equal 404, stat("c", to: simulator).status
    assert_equal 201, api("POST", "/files/a/b.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] }, to: simulator).status
    assert_equal 409, begin_upload_status("c/d.bin", to: simulator)
    assert_equal({ "files" => 1, "folders" => 1, "cursors" => 0 }, control("GET", "ready", to: simulator).json["namespace"]["state"])
  end

  # The default site policy creates every missing parent; a profile that turns always_mkdir_parents
  # off refuses a write whose parent is missing with not-found unless the request sends
  # mkdir_parents true, as Files.com's find_folder does, and says so in its readiness.
  def test_a_site_policy_without_always_mkdir_parents_creates_parents_only_when_asked
    assert_equal({ "always_mkdir_parents" => true }, control("GET", "ready").json.dig("namespace", "site_policy"))
    assert_equal 201, api("POST", "/folders/default/a/b", {}).status

    assert_equal 200, control("POST", "reset", { "profile" => { "site_policy" => { "always_mkdir_parents" => false } } }).status
    assert_equal([ { "always_mkdir_parents" => false } ] * 2, %w[profile namespace].map { |section| control("GET", "ready").json.dig(section, "site_policy") })
    [ api("POST", "/folders/x/y", {}), api("POST", "/folders/x/y", { "mkdir_parents" => false }), api("POST", "/file_actions/begin_upload/x/f.bin", {}) ].each do |refused|
      assert_equal [ 404, "not-found" ], [ refused.status, refused.json["type"] ]
    end
    assert_equal [ 404, 201 ], [ stat("x").status, api("POST", "/folders/top", {}).status ]
    assert_equal [ 201, "directory" ], [ api("POST", "/folders/x/y", { "mkdir_parents" => true }).status, stat("x").json["type"] ]
    part = begin_upload(route("deep/er/f.bin"), { "mkdir_parents" => true })
    etag = put_part(part, "bytes")
    finished = api("POST", "/files/deep/er/f.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] })
    assert_equal [ 201, 5, "directory" ], [ finished.status, finished.json["size"], stat("deep/er").json["type"] ]
    assert_equal 201, upload("top/in-existing.bin", [ "ok" ]).status

    invalid = control("POST", "reset", { "profile" => { "site_policy" => { "always_mkdir_parents" => "no" } } })
    assert_equal [ 400, "profile.site_policy.always_mkdir_parents must be true or false" ], [ invalid.status, invalid.json["error"] ]
  end

  private

  def stat(path, to: app)
    api("GET", "/files/#{path == "/" ? "%2F" : route(path)}", { "action" => "stat", "path" => path }, to:)
  end

  def delete(path)
    api("DELETE", "/files/#{path == "/" ? "%2F" : route(path)}", { "recursive" => "False", "path" => path })
  end

  def begin_upload_status(path, to: app)
    api("POST", "/file_actions/begin_upload/#{route(path)}", {}, to:).status
  end

  # Each page's paths, following the cursor as the SDKs do.
  def pages(folder, per_page)
    location = folder == "/" ? "%2F" : route(folder)
    pages = []
    cursor = nil
    loop do
      response = api("GET", "/folders/#{location}", { "per_page" => per_page, "cursor" => cursor }.compact)
      assert_equal 200, response.status, response.body
      pages << response.json.map { |entry| entry["path"] }
      cursor = response.headers["x-files-cursor"]
      return pages unless cursor

      flunk "the listing did not end: #{pages.inspect}" if pages.size >= 16
    end
  end
end
