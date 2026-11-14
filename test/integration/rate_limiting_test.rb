require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup { Rack::Attack.cache.store.clear }
  teardown { Rack::Attack.cache.store.clear }

  test "excessive login attempts from one client IP are throttled" do
    11.times do
      post login_path,
           params: { email: "nobody@example.com", password: "wrong" },
           headers: { "REMOTE_ADDR" => "203.0.113.9" }
    end
    assert_response :too_many_requests
  end

  test "excessive signup attempts from one client IP are throttled" do
    11.times do
      post signup_path,
           params: { invite_code: "x", organization: { name: "x" } },
           headers: { "REMOTE_ADDR" => "203.0.113.9" }
    end
    assert_response :too_many_requests
  end

  test "loopback traffic is never throttled" do
    status = nil
    15.times do
      post login_path,
           params: { email: "nobody@example.com", password: "wrong" },
           headers: { "REMOTE_ADDR" => "127.0.0.1" }
      status = response.status
    end
    assert_not_equal 429, status
  end
end
