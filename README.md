# Files.com Mock API Server (in Ruby)

This serves a mock Files.com API server, which is useful for testing
things like the Files.com SDKs and other direct integrations
against the Files.com API.

It is built as a simple Grape app with generated definitions for each
API endpoint.

This is meant as a minimal server for the purpose of testing basic
network operations and JSON encoding for your SDK or API client.  It
does not maintain state and it does not deeply inspect your submissions
for correctness.

Eventually we will add features intended for integration testing, such as
the ability to intentionally provoke errors.


## Requirements

* Ruby 2.4+

## Local Ruby Usage

```bash
    bundle install
    bundle exec puma
```

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
