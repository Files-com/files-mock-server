#!/bin/sh
# Security fixes the Docker image applies on top of its pinned base image, each pinned by version and SHA-256
# (see README, "Docker Image Usage"):
# - Debian 12's OpenSSL 3.0.22-1~deb12u1 (DLA-4795-1) for libssl3, libssl-dev and openssl, and libde265-0
#   1.0.11-1+deb12u3 (DLA-4789-1), from Debian's security archive;
# - json 2.19.9 (CVE-2026-54696), which replaces Ruby 3.4.11's default json 2.9.1 for Ruby run outside the bundle.
#   The server keeps the json version its Gemfile.lock names.
#
#   sh image-updates.sh fetch DIRECTORY      downloads each file below into DIRECTORY and checks its SHA-256
#   sh image-updates.sh install [DIRECTORY]  in the image build: installs the files in DIRECTORY, which must have
#                                            the SHA-256 below, or, without one, the same versions from Debian's
#                                            archive and the json archive from rubygems.org, checked against its
#                                            SHA-256 before it is installed
set -eu

# SHA-256, file name and HTTPS source of each update. The Debian files are the amd64 builds; installing without a
# DIRECTORY takes the same versions for the image's own architecture, authenticated by Debian's signed archive.
UPDATES='f0a8aa8429209e556c278a9936bbd5f7d2cdb9f7e4e23b1e43ed399217ba80c1 libssl3_3.0.22-1~deb12u1_amd64.deb https://deb.debian.org/debian-security/pool/updates/main/o/openssl/libssl3_3.0.22-1~deb12u1_amd64.deb
67033caa8a90696856c2967fbdae51e62b85878f055e01f03b0c732158c1682e libssl-dev_3.0.22-1~deb12u1_amd64.deb https://deb.debian.org/debian-security/pool/updates/main/o/openssl/libssl-dev_3.0.22-1~deb12u1_amd64.deb
6f43fb5e9f3ceb0e36c91d0a148282a8eaf174b441c17d3665b6ba049b33d2c2 openssl_3.0.22-1~deb12u1_amd64.deb https://deb.debian.org/debian-security/pool/updates/main/o/openssl/openssl_3.0.22-1~deb12u1_amd64.deb
72c3edb400c3494974181e9ca75a11d859c715c9685c38fb251783c7c8841afe libde265-0_1.0.11-1+deb12u3_amd64.deb https://deb.debian.org/debian-security/pool/updates/main/libd/libde265/libde265-0_1.0.11-1+deb12u3_amd64.deb
9b9025b7cdddafa38d316eca0b2358488e42d417045c1b90d216a9fefe46b79a json-2.19.9.gem https://rubygems.org/downloads/json-2.19.9.gem'
JSON_VERSION=2.19.9
DEFAULT_JSON=2.9.1

fail() {
  echo "image-updates.sh: $*" >&2
  exit 1
}

sha256() {
  if command -v sha256sum > /dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d ' ' -f 1
}

# Every file must be in DIRECTORY with its SHA-256.
check() {
  while read -r sum file url; do
    [ -f "$1/$file" ] || fail "$1/$file is missing"
    [ "$(sha256 "$1/$file")" = "$sum" ] || fail "$1/$file does not have SHA-256 $sum"
  done <<EOF
$UPDATES
EOF
}

# The SHA-256 of one file.
sum_of() {
  while read -r sum file url; do [ "$file" != "$1" ] || echo "$sum"; done <<EOF
$UPDATES
EOF
}

# The HTTPS source of one file.
url_of() {
  while read -r sum file url; do [ "$file" != "$1" ] || echo "$url"; done <<EOF
$UPDATES
EOF
}

# The Debian package files in a DIRECTORY.
debs() {
  while read -r sum file url; do
    case "$file" in *.deb) echo "$1/$file" ;; esac
  done <<EOF
$UPDATES
EOF
}

# name=version of each Debian package, from its file name.
packages() {
  while read -r sum file url; do
    case "$file" in *.deb) rest=${file#*_}; echo "${file%%_*}=${rest%%_*}" ;; esac
  done <<EOF
$UPDATES
EOF
}

fetch() {
  mkdir -p "$1"
  while read -r sum file url; do
    curl --fail --silent --show-error --location --proto '=https' --output "$1/$file" "$url"
  done <<EOF
$UPDATES
EOF
  check "$1"
}

install() {
  gem_dir=$(ruby -e 'print Gem.default_dir')
  if [ -n "${1:-}" ]; then
    check "$1"
    # shellcheck disable=SC2046 # one word per file: the names and vendor/cache have no spaces
    DEBIAN_FRONTEND=noninteractive dpkg -i $(debs "$1")
    gem install --local --no-document --install-dir "$gem_dir" "$1/json-$JSON_VERSION.gem"
  else
    sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources
    apt-get update
    # shellcheck disable=SC2046 # one word per name=version
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(packages)
    rm -rf /var/lib/apt/lists/*
    # The json archive must match its pin before RubyGems runs any of it, such as its native extension builds.
    download=$(mktemp -d)
    curl --fail --silent --show-error --location --proto '=https' --output "$download/json-$JSON_VERSION.gem" "$(url_of "json-$JSON_VERSION.gem")"
    [ "$(sha256 "$download/json-$JSON_VERSION.gem")" = "$(sum_of "json-$JSON_VERSION.gem")" ] \
      || fail "rubygems.org served json-$JSON_VERSION.gem with another SHA-256"
    gem install --local --no-document --install-dir "$gem_dir" "$download/json-$JSON_VERSION.gem"
    rm -r "$download"
  fi
  for package in $(packages); do
    [ "$(dpkg-query -W -f='${Version}' "${package%%=*}")" = "${package#*=}" ] || fail "${package%%=*} is not ${package#*=}"
  done
  # Removes the default json: its files, native extensions, specification and empty gem directory (rmdir fails if it
  # holds anything), so no Ruby in the image can load it, even with --disable-gems.
  ruby -rfileutils -e '
    stubs = Gem::Specification.default_stubs.select { |stub| stub.name == "json" }
    abort "image-updates.sh: the default json is #{stubs.map(&:version).join(", ")}, not #{ARGV[0]}" unless stubs.map { |stub| stub.version.to_s } == [ ARGV[0] ]
    stub = stubs.first
    lib, arch = RbConfig::CONFIG.values_at("rubylibdir", "rubyarchdir")
    FileUtils.rm_r([ File.join(lib, "json.rb"), File.join(lib, "json"), File.join(arch, "json"), stub.loaded_from ])
    FileUtils.rm_rf(File.join(Gem.default_dir, "extensions", Gem::Platform.local.to_s, Gem.extension_api_version, "json-#{ARGV[0]}"))
    Dir.rmdir(stub.full_gem_path) if File.directory?(stub.full_gem_path)' "$DEFAULT_JSON"
  [ "$(ruby -e 'require "json"; print JSON::VERSION')" = "$JSON_VERSION" ] || fail "Ruby does not load json $JSON_VERSION"
  if ruby --disable-gems -e 'require "json"' 2> /dev/null; then fail "Ruby can still load a json outside the installed gems"; fi
}

case "${1:-}" in
  fetch) [ $# -eq 2 ] || fail "usage: sh image-updates.sh fetch DIRECTORY"; fetch "$2" ;;
  install) [ $# -le 2 ] || fail "usage: sh image-updates.sh install [DIRECTORY]"; install "${2:-}" ;;
  *) fail "usage: sh image-updates.sh fetch DIRECTORY | install [DIRECTORY]" ;;
esac
