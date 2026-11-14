# Puma configuration.
#
# NOTE: PDF rendering makes an HTTP request while a request is already in
# flight, so keep the thread pool > 1 to avoid a deadlock.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count).to_i
threads min_threads_count, max_threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

# In production (containers) run a single worker; threads handle concurrency.
if ENV.fetch("RAILS_ENV", "development") == "production"
  workers ENV.fetch("WEB_CONCURRENCY", 1).to_i
  preload_app!
end

pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")
plugin :tmp_restart
