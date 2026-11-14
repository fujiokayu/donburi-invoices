# syntax=docker/dockerfile:1
# Production image for Donburi (ECS Fargate).
# Prerequisite: run `bundle install` locally once so Gemfile.lock exists.

ARG RUBY_VERSION=3.4.4
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    PORT="3000"

# Runtime dependencies, including the libraries and CJK fonts wkhtmltopdf needs.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libpq5 postgresql-client \
      fonts-noto-cjk \
      libxrender1 libxext6 libfontconfig1 libjpeg62-turbo libx11-6 libxcb1 xfonts-base xfonts-75dpi && \
    rm -rf /var/lib/apt/lists/*

# wkhtmltopdf (version pinned). Under BuildKit, TARGETARCH is injected from the
# target platform (amd64 on x86_64, arm64 on Graviton/Apple Silicon) and
# overrides the default below; the classic builder keeps the arm64 default,
# which matches the Fargate ARM64 (Graviton) runtime. Both archs ship the same
# pinned release.
ARG WKHTMLTOPDF_VERSION=0.12.6.1-3
ARG TARGETARCH=arm64
RUN curl -fsSL -o /tmp/wkhtmltox.deb \
      "https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.bookworm_${TARGETARCH}.deb" && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb && \
    rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*

# ---- build stage -------------------------------------------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}/ruby/"*/cache "${BUNDLE_PATH}/ruby/"*/bundler/gems/*/.git

COPY . .

RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ---- final stage -------------------------------------------------------------
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p log tmp storage && \
    chown -R rails:rails /rails
USER rails:rails

ENV WKHTMLTOPDF_PATH="/usr/local/bin/wkhtmltopdf"

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
