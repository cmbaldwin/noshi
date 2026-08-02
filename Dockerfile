# syntax=docker/dockerfile:1
# check=error=true

# Production Dockerfile. Build via Kamal:
#   bundle exec kamal deploy
# Or by hand:
#   docker build -t noshi .
#   docker run -d -p 80:80 -e RAILS_MASTER_KEY=$(cat config/master.key) --name noshi noshi

ARG RUBY_VERSION=4.0.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Runtime packages: jemalloc (memory), sqlite3 (database), libvips (ActiveStorage
# image thumbnails for community background uploads).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libsqlite3-0 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage — gems + asset precompile, discarded from final image
FROM base AS build

# Serialize native gem compiles under Rosetta/amd64 on Escalante (8GB host).
# Parallel make + jemalloc LD_PRELOAD often OOMs or fails nio4r/libev.
ENV MAKEFLAGS="-j1" \
    BUNDLE_JOBS="1" \
    LD_PRELOAD=""

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/

# Precompile assets without needing the real RAILS_MASTER_KEY (tailwindcss-rails
# hooks tailwind build into assets:precompile)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Non-root runtime user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
