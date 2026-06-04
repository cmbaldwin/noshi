require "socket"
require "net/http"

namespace :test do
  desc "Run the browser JS smoke test (preview, buttons, and download). " \
       "Boots a local server unless SMOKE_BASE_URL is set."
  task smoke: :environment do
    smoke = SmokeRunner.new
    smoke.run!
  end
end

desc "Pre-build gate: run the Ruby test suite and the browser JS smoke test. " \
     "Run this (or let the Kamal pre-build hook run it) before building/deploying."
task prebuild: ["test", "test:smoke"] do
  puts "\n✓ prebuild checks passed."
end

# Boots a throwaway Rails server, waits for it to come up, runs the Playwright
# smoke test against it, then tears the server down. Set SMOKE_BASE_URL to skip
# booting and test an already-running server (e.g. a deployed site).
class SmokeRunner
  SMOKE_SCRIPT = "test/javascript/smoke.test.mjs".freeze

  def run!
    ensure_node!
    ensure_node_modules!

    if (base_url = ENV["SMOKE_BASE_URL"])
      run_smoke(base_url)
      return
    end

    build_css
    port = free_port
    base_url = "http://127.0.0.1:#{port}"
    pid = boot_server(port)
    begin
      wait_for_server(base_url)
      run_smoke(base_url)
    ensure
      stop_server(pid)
    end
  end

  private

  def ensure_node!
    return if system("node", "--version", out: File::NULL, err: File::NULL)

    abort "✗ Node.js is required to run the JS smoke test but `node` was not found on PATH."
  end

  def ensure_node_modules!
    return if Dir.exist?("node_modules/playwright")

    puts "== Installing JS smoke-test dependencies (npm install) =="
    unless system("npm", "install")
      abort "✗ `npm install` failed. Install Node deps before running the smoke test."
    end
    unless system("npx", "playwright", "install", "chromium")
      abort "✗ Failed to install the Playwright Chromium browser. " \
            "Run `npm run smoke:install` and retry."
    end
  end

  def build_css
    puts "== Building Tailwind CSS =="
    Rake::Task["tailwindcss:build"].invoke
  end

  def free_port
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server.close
    port
  end

  def boot_server(port)
    puts "== Booting Rails server on port #{port} =="
    env = { "RAILS_ENV" => ENV["SMOKE_RAILS_ENV"] || "development" }
    # Use a port-scoped pidfile so the smoke server never collides with a
    # `bin/dev` server that may already be running.
    Process.spawn(
      env,
      "bin/rails", "server", "-p", port.to_s, "-b", "127.0.0.1",
      "-P", "tmp/pids/smoke-#{port}.pid"
    )
  end

  def wait_for_server(base_url, timeout: 60)
    deadline = Time.now + timeout
    uri = URI("#{base_url}/up")
    loop do
      begin
        return if Net::HTTP.get_response(uri).is_a?(Net::HTTPSuccess)
      rescue StandardError
        # server not up yet
      end
      abort "✗ Server did not become ready within #{timeout}s." if Time.now > deadline
      sleep 0.5
    end
  end

  def run_smoke(base_url)
    puts "== Running JS smoke test against #{base_url} =="
    ok = system({ "BASE_URL" => base_url }, "node", SMOKE_SCRIPT)
    abort "✗ JS smoke test failed." unless ok
  end

  def stop_server(pid)
    return unless pid

    Process.kill("TERM", pid)
    # Reap, escalating to KILL if it doesn't exit promptly.
    10.times do
      return if Process.waitpid(pid, Process::WNOHANG)

      sleep 0.3
    end
    Process.kill("KILL", pid)
    Process.waitpid(pid)
  rescue Errno::ESRCH, Errno::ECHILD
    # already gone
  end
end
