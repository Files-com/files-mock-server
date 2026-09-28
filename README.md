# Files.com Mock API Server (in Ruby)

This serves a mock Files.com API server, which is useful for testing
things like the Files.com SDKs and other direct integrations
against the Files.com API.

Files.com is the cloud-native, next-gen MFT, SFTP, and secure file-sharing platform that replaces brittle legacy servers with one always-on, secure fabric. Automate mission-critical file flows—across any cloud, protocol, or partner—while supporting human collaboration and eliminating manual work.

With universal SFTP, AS2, HTTPS, and 50+ native connectors backed by military-grade encryption, Files.com unifies governance, visibility, and compliance in a single pane of glass.

The server has two modes, chosen when it starts:

* **Legacy mode** (the default) is a simple Grape app with generated
  definitions for each API endpoint. It checks required parameters and
  parameter types, then returns a fixed example response. It does not
  maintain state and it does not deeply inspect your submissions for
  correctness. This is useful for testing basic network operations and
  JSON encoding for your SDK or API client.
* **Simulation mode** (opt-in) keeps records and files in memory for a
  small, listed set of operations, so a test can create a user and find
  it again, page through results, upload a file and download the same
  bytes, and trigger a transient error on purpose. Requests outside that
  set fail with a clear error instead of returning an example response.

Neither mode checks credentials. Send any placeholder API key; never use
real Files.com credentials with the mock server.

## Requirements

* Ruby 3.2.2 or newer (the Docker image uses Ruby 3.4.4)
* Bundler

## Local Ruby Usage

Install dependencies once:

```bash
bundle install
```

Start the legacy server, which listens on port 4041 on all IPv4
interfaces (`0.0.0.0`):

```bash
bundle exec puma
```

Start the simulation server, which listens on `127.0.0.1:4041`:

```bash
FILES_MOCK_MODE=simulation bundle exec puma
```

`FILES_MOCK_MODE` is read once at startup. Leaving it unset, empty, or
set to `legacy` starts the legacy server. Any other value stops startup
with an error, so a typo cannot silently start the wrong server.

To choose another port while keeping the simulation server on loopback,
pass Puma's `-b` option, for example `-b tcp://127.0.0.1:4051`. Read
[Ports and interfaces](#ports-and-interfaces) before using `-p` or your
own Puma configuration file.

## Docker Image Usage

We also supply a docker image for easier accessibility. First install docker; then, execute the following:

```bash
docker run -p 40410:4041 -it filescom/files-mock-server:latest
```

The image will be pulled from docker-hub, and the mock server can be accessed via the open port bound on the host machine.

Example:

```bash
curl 127.0.0.1:40410/api/rest/v1/users
```

To run the simulation server in Docker, tell it to listen on the
container's interfaces and publish the port on your machine's loopback
address only:

```bash
docker run --rm -e FILES_MOCK_MODE=simulation -e FILES_MOCK_TRANSFER_ORIGIN=http://127.0.0.1:40410 -p 127.0.0.1:40410:4041 filescom/files-mock-server:latest -b tcp://0.0.0.0:4041
```

`FILES_MOCK_TRANSFER_ORIGIN` tells the simulator the address your tests
use, so the upload and download URLs it returns point at the published
port (see [Upload and download URLs](#upload-and-download-urls)).

In CI, a simulation server can run as a service container bound to
`tcp://0.0.0.0:4041` when the job network is isolated to that job.

## Ports and interfaces

The bundled `config/puma.rb` chooses the interface for each mode: the
legacy server listens on all IPv4 interfaces (`tcp://0.0.0.0:4041`) and
the simulation server on loopback (`tcp://127.0.0.1:4041`). Puma's `-b`
option replaces that bind, so `-b tcp://127.0.0.1:4051` moves the
simulation server to another port while keeping it on loopback.

Puma's `-p PORT` option also replaces the configured interface,
including the simulation server's loopback default. It binds `::` (all
IPv6 interfaces, which on most systems also accept IPv4 connections)
when the machine has a non-loopback IPv6 interface, and `0.0.0.0`
otherwise. Use `-b tcp://0.0.0.0:PORT` for an IPv4-only bind.

The simulation server's loopback default, its refusal to run with Puma
workers, Puma's own request body limit and the way Puma reads request
bodies (see [Limits](#limits)) all come from the bundled
`config/puma.rb`. If you start Puma with your own configuration file
instead, bind to loopback, run without workers, and set
`http_content_length_limit` and `queue_requests false` yourself.

## Simulation Mode

Everything below applies only when `FILES_MOCK_MODE=simulation`.

### Simulated operations

| Operation      | Request                           | Success                          |
| -------------- | --------------------------------- | -------------------------------- |
| `users.create` | `POST /api/rest/v1/users`         | `201` and the new user           |
| `users.list`   | `GET /api/rest/v1/users`          | `200` and an array of users      |
| `users.find`   | `GET /api/rest/v1/users/{id}`     | `200` and the user               |
| `users.update` | `PATCH /api/rest/v1/users/{id}`   | `200` and the updated user       |
| `users.delete` | `DELETE /api/rest/v1/users/{id}`  | `204` with an empty body         |
| `files.begin_upload` | `POST /api/rest/v1/file_actions/begin_upload/{path}` | `200` and an array with one upload part |
| `files.finalize_upload` | `POST /api/rest/v1/files/{path}` with `action: "end"` | `201` and the new file, `200` when it replaces one |
| `files.download` | `GET /api/rest/v1/files/{path}` | `200` and the file with a `download_uri` |
| `files.metadata` | `GET /api/rest/v1/file_actions/metadata/{path}` | `200` and the file |

Uploaded bytes go to the `upload_uri` each upload part names, and
downloads come from the `download_uri`; see [Files](#files).

Send parameters the way the Files.com SDKs do: in the query string for
`GET` and `DELETE`, and as a JSON object body with
`Content-Type: application/json` for `POST` and `PATCH`.

Any other request under `/api/rest/v1/` returns `501` with the type
`simulation/not-supported` (a `HEAD` request gets the same status with an
empty body), and so does a simulated operation that sends a parameter the
Files.com API schema declares but the simulator does not model. The
readiness response below lists the simulated operations.

How users behave:

* IDs start at 1 and increase by one for each created user. A deleted
  user's ID is never reused until the next reset.
* A created user contains its `id` and the fields you supplied that are
  part of the User object. Fields the real API computes or defaults
  (such as `created_at`) are not simulated.
* An update changes only the fields you supply and keeps the ID and
  every other field. Sending `null` for an optional field clears it.
* Finding, updating, or deleting a user that does not exist returns
  `404` with the type `not-found`, like the Files.com API.
* `password`, `password_confirmation`, `change_password`,
  `change_password_confirmation` and `imported_password_hash` are
  checked to be strings and then discarded. They never appear in
  responses or in the journal.
* Parameters are checked against the Files.com API schema before
  anything changes: required parameters, strings, whole numbers
  (including 32-bit ranges), `true`/`false`, enumerated values such as
  `ssl_required` and `authentication_method`, and date-times such as
  `authenticate_until`. Date-times must be ISO 8601 with a UTC offset
  (for example `2030-01-02T03:04:05+02:00`) and are returned in UTC
  (`2030-01-02T01:04:05Z`), to whole seconds: fractional seconds are
  discarded, so `2030-01-02T03:04:05.750Z` is returned as
  `2030-01-02T03:04:05Z`. Dates and times that do not exist, such as
  February 30 or 24:00, are rejected rather than rolled over. Invalid
  values return `422` with the type `bad-request`, and nothing is created
  or changed.
* Schema-declared parameters with other kinds of values, such as
  `avatar_file`, and with effects the simulator does not model, such as
  `group_id` or `new_owner_id`, return `501`.
* Keys the schema does not declare for the operation are ignored, as the
  Files.com API ignores them. A misspelled parameter name, such as
  `perpage`, is therefore not reported.
* The simulator does not check credentials, username uniqueness, or
  whether IDs in one record refer to other records.

### Pagination

`GET /api/rest/v1/users` returns users in ID order, which is the order
they were created. `per_page` must be a whole number from 1 to 10000 and
defaults to 1000. When more users remain, the response carries the same
cursor in both the `X-Files-Cursor` and `X-Files-Cursor-Next` headers;
pass it back as `cursor`, with the same `per_page`, to get the next page.
The last page has neither header.

Cursors are opaque. A cursor is accepted only by the simulator process
that issued it, with the same `per_page`, until the next reset; anything
else returns `422` with the type `bad-request/invalid-cursor`.

A cursor continues after the last user it returned. Users created during
a traversal appear on later pages, users deleted before they are reached
are skipped, and no user is returned twice.

Filtering, sorting and search parameters (`sort_by`, `filter`,
`filter_gt`, `filter_prefix`, `ids`, `search`, and the like) return
`501` rather than an unfiltered list.

### Files

Simulation mode keeps files and their bytes in memory, so a test can
upload a file with a Files.com SDK and download exactly the same bytes,
whole or as a single byte range.

A file path is a name in the simulator's own namespace: nothing is read
from or written to the machine running the server. Paths keep their
spaces, Unicode characters and percent signs. The path in a URL is
decoded exactly once, so `/api/rest/v1/files/folder/a%252Fb.txt` names
the file `a%2Fb.txt` in `folder`, and the Go SDK (which sends a path's
slashes as they are) and the Python SDK (which encodes them as `%2F`)
name the same file.

Paths are stored and returned exactly as sent. To find paths the
Files.com API would treat differently, the simulator compares them as
the API does, using the comparison map in `shared/path_comparison.json`
(version 1, for MySQL's `utf8mb4_0900_ai_ci`), which comes from the
Files.com server. It uses the comparison only to refuse paths it does
not model; see
[Differences from the Files.com API](#differences-from-the-filescom-api).

#### Uploading

The SDKs' upload methods take these steps for you:

1. `POST /api/rest/v1/file_actions/begin_upload/{path}` starts an upload
   and returns `200` with an array of one upload part: its `ref`,
   `part_number` and the `upload_uri` to send that part's bytes to. Send
   the `ref` and the next `part` number to get the next part's URL.
2. `PUT` each part's raw bytes to its `upload_uri`, with any content type
   or none. The response is `200` with an `ETag` header: the SHA-256 of
   the part's bytes, in quotes. Sending a part again with the same bytes
   returns the same ETag; different bytes for a stored part get `501`.
3. `POST /api/rest/v1/files/{path}` with `action: "end"`, the `ref`, and
   `etags` listing every part as `{"etag": ..., "part": ...}`. This
   publishes the file in one step and returns `201` and the file, or
   `200` when it replaces an existing file.

Parts are joined in part number order, whatever order they arrived or
were listed in, and a part number may be sent as a string (`"2"`), as
the Go SDK does. Before anything is published, finalizing checks that
the listed parts are numbered 1 to N with no gaps or repeats, that each
was uploaded with the listed ETag, that no uploaded part is left out,
and, when `size` is sent, that the parts add up to it. A failed check
changes nothing: the upload stays open so it can be finalized again,
and an existing file keeps its bytes. A finalized upload's `ref` is no
longer valid, so a repeated finalize gets `404`.

| Problem when finalizing | Status | Type |
| ----------------------- | ------ | ---- |
| No `ref` | 422 | `bad-request/request-params-required` |
| An unknown `ref`, or one for another path | 404 | `not-found/file-upload-not-found` |
| No parts, a listed part that was not uploaded, or a wrong ETag | 422 | `processing-failure/file-not-uploaded` |
| Part numbers with a gap or a repeat, or an uploaded part left out | 422 | `bad-request/invalid-etags` |
| A `size` the parts do not add up to | 422 | `bad-request/request-params-invalid` |

An empty file is an upload of one empty part. `provided_mtime` accepts a
time with a UTC offset or, as the Python SDK sends it, without one,
which is read as UTC; it is returned in UTC to whole seconds.

The upload parts advertise `parallel_parts: false`, `retry_parts: true`
and a `partsize` of 5 MiB, or `FILES_MOCK_MAX_BODY_BYTES` when that is
smaller. These tell a client how to upload; the simulator does not
enforce them. It accepts parts sent at the same time or out of order and
joins them by part number when the upload is finalized, so a passing
test does not show that a client sends one part at a time. SDKs may send
other part sizes, and the simulator accepts them:
the Go SDK sends up to 5 MiB per part whatever `partsize` says, and the
Python SDK follows `partsize` and adds an empty last part when a file
fills its last part exactly. Every part body must fit in
`FILES_MOCK_MAX_BODY_BYTES`, so raise it to at least 5 MiB, for example
`FILES_MOCK_MAX_BODY_BYTES=8388608`, before uploading files over 1 MiB
with the Go SDK.

#### Downloading

`GET /api/rest/v1/files/{path}` returns the file with a `download_uri`,
and `GET /api/rest/v1/file_actions/metadata/{path}` returns it without
one. A file that does not exist gets `404` with the type `not-found`.

`GET` on the `download_uri` returns `200` with the file's bytes,
`Content-Length`, `Content-Type: application/octet-stream`,
`Accept-Ranges: bytes` and an `ETag`. With a `Range` header naming one
byte range (`bytes=7-99`, `bytes=7-` or `bytes=-100`), it returns `206`
with just those bytes and a `Content-Range` header. A range that ends
past the end of the file is shortened to it, and one that starts past
the end gets `416` with `Content-Range: bytes */{size}`. Any other
`Range` value, such as several ranges, is ignored and the whole file is
sent, as HTTP allows; so is every range on an empty file. `HEAD` is not
simulated.

A download URL names one version of a file. Once the file is replaced,
its old download URLs get `409` with the type `download_source_changed`,
and the Go SDK then requests a new URL. A download already in progress
finishes with the bytes it started with.

#### Upload and download URLs

The `upload_uri` and `download_uri` values are URLs under
`/__files_mock/transfer/`. Use them as they are: they are not Files.com
API paths, and they work only on the simulator process that issued them,
until its next reset. An upload URL works until the upload is finalized;
its `expires` time, 15 minutes after it was issued, is not enforced.

The URLs start with the address and port the request arrived on, such as
`http://127.0.0.1:4041`. They never reflect the request's `Host` header.
When your tests reach the server at a different address, such as a port
published from a Docker container, set `FILES_MOCK_TRANSFER_ORIGIN` to
that origin, for example `http://127.0.0.1:40410`. The server refuses to
start if it is not an `http` or `https` origin without a path.

#### Example

Start a simulator that accepts 5 MiB parts:

```bash
FILES_MOCK_MODE=simulation FILES_MOCK_MAX_BODY_BYTES=8388608 bundle exec puma
```

With the Go SDK:

```go
config := files.Config{APIKey: "placeholder", EndpointOverride: "http://127.0.0.1:4041"}.Init()
client := &file.Client{Config: config}
if err := client.Upload(file.UploadWithFile("report.pdf"), file.UploadWithDestinationPath("reports/report.pdf")); err != nil {
	log.Fatal(err)
}
if _, err := client.DownloadToFile(files.FileDownloadParams{Path: "reports/report.pdf"}, "report-copy.pdf"); err != nil {
	log.Fatal(err)
}
```

With the Python SDK:

```python
import files_sdk

files_sdk.base_url = "http://127.0.0.1:4041"
files_sdk.set_api_key("placeholder")
files_sdk.file.upload_file("report.pdf", "reports/report.pdf")
files_sdk.file.download_file("reports/report.pdf", "report-copy.pdf")
```

The same steps with `curl` and `jq`:

```bash
API=http://127.0.0.1:4041/api/rest/v1
PART=$(curl -s -X POST $API/file_actions/begin_upload/hello.txt -H 'Content-Type: application/json' -d '{}')
REF=$(jq -r '.[0].ref' <<<"$PART")
ETAG=$(curl -s -D - -o /dev/null -X PUT --data-binary 'hello, world' "$(jq -r '.[0].upload_uri' <<<"$PART")" |
  awk 'tolower($1) == "etag:" { gsub(/[\r"]/, "", $2); print $2 }')
curl -s -X POST $API/files/hello.txt -H 'Content-Type: application/json' \
  -d "{\"action\": \"end\", \"ref\": \"$REF\", \"etags\": [{\"etag\": \"$ETAG\", \"part\": 1}]}" | jq -c .
curl -s -r 7-11 "$(curl -s $API/files/hello.txt | jq -r .download_uri)"; echo   # world
```

#### Differences from the Files.com API

* Paths are stored exactly as sent, but the Files.com API compares them
  with its comparison map, so `café.bin` and `CAFE.bin` are one file
  there, and it has folders. Rather than store a file the API would
  not, the simulator returns `501` for a new path that compares equal
  to an existing file spelled differently, a file where other files
  make a folder, a file inside a file (compared the same way), and a
  folder's metadata. The same spelling still replaces its own file. A
  file's parent folders are implied, as on a site that creates parent
  folders automatically, so `mkdir_parents` has no further effect.
* The API rejects a path with a name that, compared that way, is empty,
  `.` or `..`, or contains a slash, such as `．．` (two fullwidth dots)
  or `a℀b`. The simulator returns `501` for these instead of the API's
  error, and also for paths the API would rewrite: with a leading,
  trailing or repeated slash, a `.` or `..` segment, or a backslash.
  The API's other path rules, such as length limits and characters it
  refuses, are not checked, so a path accepted here may still be
  refused by the API. A `path` parameter that disagrees with the path
  in the URL gets `422`.
* The upload profile is advertised, not enforced: parts sent at the
  same time or out of order are accepted. `size` is optional, as it is
  in the SDKs' own known-size uploads, and is checked only when it is
  sent. The simulator does not model or certify uploads of unknown
  size, adaptive part sizes or parallel parts, even where it accepts
  such requests.
* The simulator checks that every uploaded part is listed and that a
  sent `size` matches the parts. The Files.com API may accept such
  requests, so a rejection here does not prove the API would reject
  them.
* `with_direct_connection_info` is accepted, and no direct connection
  information is returned, which the API also allows.
* These requests get `501`: `begin_upload` with `parts`, `restart`,
  `with_rename` or `buffered_upload`, or with a `ref` but no `part`;
  `POST /api/rest/v1/files/{path}` with an `action` other than `end`,
  or with `custom_metadata`, `length`, `part`, `parts`, `restart`,
  `copy_behaviors`, `structure`, `with_rename` or `buffered_upload`;
  and `GET /api/rest/v1/files/{path}` or
  `GET /api/rest/v1/file_actions/metadata/{path}` with `preview_size`,
  `with_previews` or `with_priority_color`, or, for downloads, with
  `action`.
* Files are never deleted, moved or copied, folders are not listed, and
  checksums such as `md5` are not returned.

### Control endpoints

Tests control the simulator directly through endpoints under
`/__files_mock/v1`. These requests are never counted as API traffic.
`POST` requests must send `Content-Type: application/json`.

#### Readiness: `GET /__files_mock/v1/ready`

Poll this until it answers `200`, with a time limit, before running
tests. It identifies the server and what it simulates:

```json
{
  "status": "ready",
  "mode": "simulation",
  "contract_version": 1,
  "simulator_version": "1.0",
  "schema_sha256": "583b5112…",
  "instance": "110241a94a7c",
  "epoch": 0,
  "operations": [
    { "id": "users.create", "method": "POST", "path": "/api/rest/v1/users", "swagger_operation_id": "PostUsers" },
    { "id": "files.begin_upload", "method": "POST", "path": "/api/rest/v1/file_actions/begin_upload/{path}", "swagger_operation_id": "FileActionBeginUpload" }
  ],
  "transfers": {
    "operations": [ { "id": "transfers.upload_part", "method": "PUT" }, { "id": "transfers.download", "method": "GET" } ],
    "origin": null,
    "upload_parts": { "http_method": "PUT", "parallel_parts": false, "retry_parts": true, "partsize": 1048576 },
    "max_uploads": 64,
    "max_parts": 64,
    "state": { "uploads": 0, "files": 0, "bytes_in_use": 0 }
  },
  "fixtures": [ "users" ],
  "faults": { "match": { "users.create": "username", "users.list": null, "users.find": "id", "files.begin_upload": "path", "transfers.upload_part": [ "path", "part" ] }, "statuses": [ 429, 500, 502, 503, 504 ] },
  "pagination": { "order": "id", "default_per_page": 1000, "max_per_page": 10000, "next_cursor_headers": [ "X-Files-Cursor", "X-Files-Cursor-Next" ] },
  "limits": { "max_records": 1000, "max_journal_entries": 10000, "max_body_bytes": 1048576, "max_transfer_bytes": 33554432 },
  "state": { "users": 0, "journal_entries": 0, "journal_complete": true, "pending_faults": 0 }
}
```

(Shortened.) `contract_version` changes when this control or simulation
contract changes incompatibly. `schema_sha256` identifies the API schema
subset the simulator validates against. `instance` is different for
every server process, and `epoch` counts resets. `transfers` lists the
byte transfers to issued URLs, the upload profile and transfer limits,
the `FILES_MOCK_TRANSFER_ORIGIN` setting (`null` when URLs use the
address each request arrived on), and the unfinished uploads, files and
file bytes held now.

#### Reset and fixtures: `POST /__files_mock/v1/reset`

Replaces all state at once: users, the ID counter, uploads, files,
fault rules and the journal. Every user fixture goes through the same checks as
`users.create` and gets IDs from 1 in the order given. Sending the same
fixtures always produces the same users and IDs.

```bash
curl -X POST http://127.0.0.1:4041/__files_mock/v1/reset \
  -H 'Content-Type: application/json' \
  -d '{"fixtures": {"users": [{"username": "alice"}, {"username": "bob", "ssl_required": "always_require"}]}}'
```

```json
{ "epoch": 1, "users": [ 1, 2 ] }
```

Send `{}` to reset to an empty simulator. If any fixture is invalid or
over a limit, the reset is refused and the previous state is kept. After
a reset, cursors, upload refs, and upload and download URLs issued before
it are rejected, and a request the simulator was already handling when
the reset happened, including a part body it was still receiving, is
refused with `409` (`simulation/stale-request`) instead of being applied
to the new state. A download already being sent finishes. Reset when
your test's own requests have finished.

#### Faults: `POST /__files_mock/v1/faults` and `GET /__files_mock/v1/faults`

A fault rule makes one future request fail with an HTTP error, and it is
used exactly once. A request is matched after its body has been read and
parsed, and before its parameters are validated or anything changes. A
request refused while being read (a body that is too large, not JSON, or
not valid JSON) never counts toward a rule. A request with invalid
parameters does count, and gets the fault instead of the `422`.

| Field         | Required | Meaning |
| ------------- | -------- | ------- |
| `operation`   | yes      | A simulated operation, for example `users.update`. |
| `status`      | yes      | `429`, `500`, `502`, `503` or `504`. |
| `match`       | no       | Limit the rule to one record: `{"id": 2}` for `users.find`, `users.update` and `users.delete`, or `{"username": "alice"}` for `users.create`. `users.list` rules match every list request. File operations and downloads match on the file's `path`, and `transfers.upload_part` on `path`, `part` or both, as in `{"path": "reports/report.pdf", "part": 2}`. |
| `attempt`     | no       | Fail the Nth matching request after the rule is added (1 to 100, default 1). |
| `retry_after` | no       | Seconds to send in a `Retry-After` header (0 to 60). |

For example, to make the first update of user 2 fail once:

```bash
curl -X POST http://127.0.0.1:4041/__files_mock/v1/faults \
  -H 'Content-Type: application/json' \
  -d '{"operation": "users.update", "match": {"id": 2}, "status": 503, "retry_after": 1}'
```

The next `PATCH /api/rest/v1/users/2` returns:

```json
{ "error": "Simulated 503 response from fault rule 1", "http-code": 503, "title": "Service Unavailable", "type": "simulation/injected-fault" }
```

Requests for other operations or other records never use the rule, even
when they arrive at the same time. A new rule that could match the same
requests as a rule that is still pending is refused with `409`.

A fault stores and publishes nothing, so a test can check an SDK's own
retry. To make the first attempt at part 2 of an upload fail once:

```bash
curl -X POST http://127.0.0.1:4041/__files_mock/v1/faults \
  -H 'Content-Type: application/json' \
  -d '{"operation": "transfers.upload_part", "match": {"path": "reports/report.pdf", "part": 2}, "status": 503, "retry_after": 0}'
```

`GET /__files_mock/v1/faults` lists every rule since the last reset as
`pending` or `consumed`, with `matched_requests` and the journal
`consumed_by_request` sequence number. Check that the faults your test
added were consumed; a pending rule means the failure never happened.

#### Journal: `GET /__files_mock/v1/journal`

Lists the API requests since the last reset, oldest first:

```json
{
  "epoch": 1,
  "entries": [
    { "seq": 2, "epoch": 1, "method": "PATCH", "path": "/api/rest/v1/users/2", "operation": "users.update", "id": 2, "fault_id": 1, "status": 503 }
  ],
  "limit": 10000,
  "dropped": 0,
  "complete": true
}
```

Entries record the operation (or `null` for a request that is not
simulated), the record ID, the response status and any fault rule used.
File and transfer entries also name the `upload`, `part` and file
`version` they used, and `bytes` and `sha256` for the bytes a part
stored or a finalize published. A download entry has the length of the
response and the version's SHA-256; it is written when the response
starts, so it does not show how many bytes the client received. Compare
downloaded bytes yourself. Entries never contain request bodies, file
content, query strings, headers or credentials. When the journal is full, later requests still run, but
they are counted in `dropped` and `complete` becomes `false`; treat an
incomplete journal as missing evidence.

### Errors from the simulator itself

| Status | Type | Meaning |
| ------ | ---- | ------- |
| 501 | `simulation/not-supported` | The operation, parameter or request body type is not simulated. |
| 409, 413 | `simulation/limit-exceeded` | A limit below was reached. Nothing was changed. (Puma's own `413` for an oversized body is plain text; see Limits.) |
| 409 | `simulation/stale-request` | The simulator was reset while it was handling the request. |
| 429, 5xx | `simulation/injected-fault` | A fault rule you added. |
| 400, 409, 415 | `simulation/invalid-control-request` | A control request was malformed or conflicts with a pending fault rule. |
| 404 | `simulation/unknown-control` | There is no such control endpoint. |

Errors use the Files.com API error shape, with `error`, `http-code`,
`title` and `type` fields.

### Limits

Simulation mode rejects work over these limits instead of truncating it.
Set them with environment variables at startup:

| Variable | Default | Maximum | Limits |
| -------- | ------- | ------- | ------ |
| `FILES_MOCK_MAX_RECORDS` | 1000 | 100000 | Users held at once, and separately files held at once. |
| `FILES_MOCK_MAX_JOURNAL_ENTRIES` | 10000 | 100000 | Journal entries kept between resets. |
| `FILES_MOCK_MAX_BODY_BYTES` | 1048576 | 16777216 | Size of a request body, including each upload part. |
| `FILES_MOCK_MAX_TRANSFER_BYTES` | 33554432 | 1073741824 | File content held in memory. |

At most 100 fault rules can be added between resets, 64 uploads can be
unfinished at once, and an upload can have up to 64 parts. These limits
protect the machine running your tests; they are not Files.com API
limits.

`FILES_MOCK_MAX_TRANSFER_BYTES` counts all the file content the
simulator holds: uploaded parts, files, a part body from the moment the
simulator starts reading it, and a replaced file's bytes until a
download that started before the replacement finishes. A part body that
would pass the limit is refused with `409` before it is read. A reset
releases everything except bytes a download in progress is still
sending; the `transfers.state.bytes_in_use` readiness field shows the
current count.

A chunked upload part has no declared length, so it reserves
`FILES_MOCK_MAX_BODY_BYTES` until its actual size is known. Near the
transfer limit, even a small chunked part can therefore get `409`.

Beyond that content, the server holds at most one request body for each
request Puma is serving. With the bundled `config/puma.rb`, Puma reads
each body on the thread that serves its request (up to 5 threads unless
`-t` sets more), and connections beyond that wait unread. A body of up
to 112 KiB is kept in memory, and a larger one in an unlinked temporary
file until the simulator reads it. JSON request bodies are then parsed
in memory, and downloads are sent in 64 KiB slices of the stored bytes.
The path comparison map, loaded once at startup, adds a fixed amount.
Ruby's own memory, including garbage it has not yet collected, comes on
top of these, so measure your own setup if memory is tight. A client
that sends its body slowly keeps its thread busy until it finishes.

A request body over `FILES_MOCK_MAX_BODY_BYTES` gets `413` and changes
nothing. With the bundled `config/puma.rb`, Puma refuses it before the
simulator sees the request: a declared `Content-Length` over the limit
before any of the body is read, and a chunked body as soon as the
received chunks cross the limit. That `413` is Puma's plain-text
`Payload Too Large` response, not the JSON error shape, Puma closes the
connection, and the request does not appear in the journal. The
simulator checks the same limit itself, so under another server or
Puma configuration an oversized body still gets a journaled `413`
(`simulation/limit-exceeded`).

### Isolation

Each simulation server keeps its state in its own process memory and
shares nothing with other servers, even when they are given the same
fixtures. Start one server per test run, on its own port or in its own
container, and reset it between scenarios. Simulation mode refuses to
start Puma with workers (`-w` or `WEB_CONCURRENCY`), because each worker
would hold a separate copy of the state.

The simulator has no authentication of its own. It listens on loopback
by default, does not send CORS headers, and should only be reachable
from the tests that own it.

### Not yet simulated

Simulation mode does not yet cover the file and folder operations beyond
[Files](#files), such as deleting, moving, copying and listing,
resources other than users and files, or randomly generated errors.
Requests for these return `501` in simulation mode. Use legacy mode for
tests that only need example responses for them.

## Checking This Server

`./test.sh` runs the server's own tests. They start real servers on free
loopback ports and do not modify any files. Run `bundle install` first,
or run `./test.sh true` to install dependencies and then test.

## Getting Support

The Files.com team is happy to help with any issues you may have running the Files.com mock server.

Just email <support@files.com> and we'll get the process started.
