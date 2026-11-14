# Rate limiting for the publicly hosted instance. Guards the auth endpoints
# against brute force and gives crude flood protection, without affecting
# normal use. Tuned so it never interferes with internal traffic.
class Rack::Attack
  # Self-contained store so throttling does not depend on the app's cache
  # configuration. State is per-process (the service runs a single task).
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Resolve the real client via the app's trusted-proxy config, so requests
  # arriving through the CDN/load balancer are keyed by the originating client
  # rather than the edge address.
  def self.client_ip(req)
    ActionDispatch::Request.new(req.env).remote_ip
  end

  # Never limit internal loopback traffic (the PDF renderer calls back in).
  safelist("allow-loopback") do |req|
    ip = Rack::Attack.client_ip(req)
    ip == "127.0.0.1" || ip == "::1"
  end

  # Optional operator safelist (comma/space separated IPs), e.g. a host used to
  # seed preparation traffic or to demo from.
  safelist("allow-operator") do |req|
    ENV.fetch("RATE_LIMIT_SAFELIST", "").split(/[,\s]+/).include?(Rack::Attack.client_ip(req))
  end

  # Crude flood protection. Health checks and static assets are exempt.
  throttle("req/ip", limit: 300, period: 60) do |req|
    unless req.path == "/up" || req.path.start_with?("/assets")
      Rack::Attack.client_ip(req)
    end
  end

  # Brute-force protection on the authentication endpoints.
  throttle("logins/ip", limit: 10, period: 60) do |req|
    Rack::Attack.client_ip(req) if req.post? && req.path == "/login"
  end

  throttle("signups/ip", limit: 10, period: 60) do |req|
    Rack::Attack.client_ip(req) if req.post? && req.path == "/signup"
  end

  # Answer throttled requests with 429 and a small retry hint.
  self.throttled_responder = lambda do |req|
    period = (req.env["rack.attack.match_data"] || {})[:period]
    headers = { "Content-Type" => "text/plain" }
    headers["Retry-After"] = period.to_s if period
    [429, headers, ["Too many requests. Please retry later.\n"]]
  end
end
