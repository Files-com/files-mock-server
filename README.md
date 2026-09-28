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
* **Simulation mode** (opt-in) keeps records in memory for a small,
  listed set of operations, so a test can create a user and find it
  again, page through results, and trigger a transient error on
  purpose. Requests outside that set fail with a clear error instead of
  returning an example response.

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
docker run --rm -e FILES_MOCK_MODE=simulation -p 127.0.0.1:40410:4041 filescom/files-mock-server:latest -b tcp://0.0.0.0:4041
```

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
workers and Puma's own request body limit all come from the bundled
`config/puma.rb`. If you start Puma with your own configuration file
instead, bind to loopback, run without workers and set
`http_content_length_limit` yourself.

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
  "schema_sha256": "4dd78120…",
  "instance": "110241a94a7c",
  "epoch": 0,
  "operations": [
    { "id": "users.create", "method": "POST", "path": "/api/rest/v1/users", "swagger_operation_id": "PostUsers" }
  ],
  "fixtures": [ "users" ],
  "faults": { "match": { "users.create": "username", "users.list": null, "users.find": "id" }, "statuses": [ 429, 500, 502, 503, 504 ] },
  "pagination": { "order": "id", "default_per_page": 1000, "max_per_page": 10000, "next_cursor_headers": [ "X-Files-Cursor", "X-Files-Cursor-Next" ] },
  "limits": { "max_records": 1000, "max_journal_entries": 10000, "max_body_bytes": 1048576 },
  "state": { "users": 0, "journal_entries": 0, "journal_complete": true, "pending_faults": 0 }
}
```

(Shortened.) `contract_version` changes when this control or simulation
contract changes incompatibly. `schema_sha256` identifies the API schema
subset the simulator validates against. `instance` is different for
every server process, and `epoch` counts resets.

#### Reset and fixtures: `POST /__files_mock/v1/reset`

Replaces all state at once: users, the ID counter, fault rules and the
journal. Every user fixture goes through the same checks as
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
a reset, cursors issued before it are rejected, and an API request the
simulator was already handling when the reset happened is refused with
`409` (`simulation/stale-request`) instead of being applied to the new
state. Reset when your test's own requests have finished.

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
| `match`       | no       | Limit the rule to one record: `{"id": 2}` for `users.find`, `users.update` and `users.delete`, or `{"username": "alice"}` for `users.create`. `users.list` rules match every list request. |
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
They never contain request bodies, query strings, headers or
credentials. When the journal is full, later requests still run, but
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
| `FILES_MOCK_MAX_RECORDS` | 1000 | 100000 | Users held at once. |
| `FILES_MOCK_MAX_JOURNAL_ENTRIES` | 10000 | 100000 | Journal entries kept between resets. |
| `FILES_MOCK_MAX_BODY_BYTES` | 1048576 | 16777216 | Size of a request body. |

At most 100 fault rules can be added between resets. These limits
protect the machine running your tests; they are not Files.com API
limits.

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

Simulation mode does not yet cover file uploads (including multipart
uploads), downloads, file and folder move and copy, resources other than
users, or randomly generated errors. Requests for these return `501` in
simulation mode. Use legacy mode for tests that only need example
responses for them.

## Checking This Server

`./test.sh` runs the server's own tests. They start real servers on free
loopback ports and do not modify any files. Run `bundle install` first,
or run `./test.sh true` to install dependencies and then test.

## Getting Support

The Files.com team is happy to help with any issues you may have running the Files.com mock server.

Just email <support@files.com> and we'll get the process started.
