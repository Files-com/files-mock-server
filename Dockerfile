# The official Ruby 4.0.9 image on Debian 12 (bookworm), pinned by its multi-platform index digest so the base cannot
# change under a build. Only linux/amd64 builds have been checked (see README).
FROM ruby:4.0.9-bookworm@sha256:ee456cdda3647aa5e9e17c81a6e528418d0f19a2222e99e347b7c5729de24dbc
LABEL maintainer="Action Verb, LLC <https://github.com/Files-com>"

WORKDIR /files-mock-server
COPY . .
# Applies the security fixes the pinned base does not have yet, which image-updates.sh pins by version and SHA-256:
# Debian 12's OpenSSL and libde265 updates, and json 2.19.9 in place of Ruby's default json 2.18.0 for Ruby run outside
# the bundle. When vendor/cache exists, they come only from there and must match those hashes; otherwise from Debian's
# signed archive and rubygems.org.
RUN if [ -d vendor/cache ]; then sh image-updates.sh install vendor/cache; else sh image-updates.sh install; fi
# Installs exactly what Gemfile.lock names with the Bundler it names under BUNDLED WITH (keep the two versions in
# step), on the base image's own RubyGems. Frozen, a Gemfile that disagrees with Gemfile.lock fails the build instead
# of changing the lock. When vendor/cache exists, Bundler is installed from its cached archive and bundle install
# uses cached gems or gems already installed in the base. A dependency missing from both fails without a fetch.
ENV BUNDLE_FROZEN=true
RUN if [ -d vendor/cache ]; then \
      gem install --local --no-document vendor/cache/bundler-4.0.21.gem && bundle install --local; \
    else \
      gem install --no-document bundler --version 4.0.21 && bundle install; \
    fi

EXPOSE 4041
ENTRYPOINT ["bundle", "exec", "puma"]
