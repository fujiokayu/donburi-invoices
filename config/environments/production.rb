require "active_support/core_ext/integer/time"
require "ipaddr"

# CloudFront origin-facing IP ranges (service CLOUDFRONT_ORIGIN_FACING in
# https://ip-ranges.amazonaws.com/ip-ranges.json). The ALB only accepts
# connections from CloudFront, so the edge address CloudFront adds to
# X-Forwarded-For always falls in one of these. Trusting them lets
# request.remote_ip resolve to the originating viewer recorded upstream in
# X-Forwarded-For instead of a CloudFront edge address.
CLOUDFRONT_ORIGIN_FACING_RANGES = %w[
  130.176.88.0/21 54.239.134.0/23 52.82.134.0/23 130.176.86.0/23
  130.176.140.0/22 130.176.0.0/18 54.239.204.0/22 130.176.160.0/19
  70.132.0.0/18 15.158.0.0/16 130.176.136.0/23 54.239.170.0/23
  130.176.96.0/19 51.74.21.0/24 54.182.184.0/22 204.246.166.0/24
  130.176.64.0/21 54.182.172.0/22 205.251.218.0/24 130.176.144.0/20
  54.182.176.0/21 130.176.78.0/23 54.182.248.0/22 64.252.128.0/18
  51.74.22.0/24 54.182.154.0/23 64.252.64.0/18 54.182.144.0/21
  54.182.224.0/21 130.176.128.0/21 52.46.0.0/18 3.172.64.0/18
  52.82.128.0/23 18.68.0.0/16 54.182.156.0/22 54.182.160.0/21
  54.182.240.0/21 51.74.20.0/24 130.176.192.0/19 130.176.76.0/24
  54.239.208.0/21 54.182.188.0/23 24.110.128.0/17 3.172.0.0/18
  130.176.80.0/22 54.182.128.0/20 130.176.72.0/22 13.124.199.0/24
  3.29.57.0/26
].freeze

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = true
  config.assets.compile = false

  # Behind the ALB; it terminates TLS. Keep assume_ssl so redirects use https,
  # but do not force_ssl at the app layer.
  config.assume_ssl = true
  config.force_ssl = false

  # Trust the proxy hops in front of the app so request.remote_ip reflects the
  # originating client in X-Forwarded-For. The ALB is a private address (trusted
  # by Rails' defaults); add the CloudFront edge ranges and any additional
  # upstream addresses supplied via TRUSTED_CLIENT_IPS (comma/space separated).
  config.action_dispatch.trusted_proxies =
    (CLOUDFRONT_ORIGIN_FACING_RANGES +
     ENV.fetch("TRUSTED_CLIENT_IPS", "").split(/[,\s]+/).reject(&:empty?))
      .map { |cidr| IPAddr.new(cidr) }

  config.log_tags = [:request_id, :remote_ip]
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false

  config.action_mailer.perform_deliveries = false

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Restrict Host header to the configured host (plus 127.0.0.1/localhost).
  # Left open (allow all) when APP_HOST is unset.
  if (app_host = ENV["APP_HOST"]).present?
    config.hosts = [app_host, "127.0.0.1", "localhost"]
    config.host_authorization = { exclude: ->(req) { req.path == "/up" } }
  end
end
