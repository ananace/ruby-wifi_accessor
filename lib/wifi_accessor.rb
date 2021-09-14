# frozen_string_literal: true

require 'capybara'
require 'capybara/poltergeist'
require 'wifi_accessor/config'
require 'wifi_accessor/data'
require 'wifi_accessor/network'
require 'wifi_accessor/network_discover'
require 'wifi_accessor/version'

Capybara.threadsafe = true
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    # logger: STDERR,
    phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
  )
end

module WifiAccessor
  class AlreadyLoggedInError < StandardError; end
  class Error < StandardError; end

  TEST_URI = URI('http://example.com').freeze

  def self.access_login(net)
    return ArgumentError, 'Unknown network' unless net.is_a? Network

  end

  def self.dev
    @dev ||= Capybara::Session.new(:poltergeist).tap do |session|
      # TODO: Config?
      session.driver.timeout = 30
    end
  end

  def self.data
    @data ||= Config.load!
  end

  def self.get(network)
    data.get(network)
  end

  def self.discover!
    res = nil
    uri = TEST_URI.dup
    attempts = 0
    # Attempt to discover connectivity/captive portal for 3 seconds
    loop do
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end

      break
    rescue SocketError # getaddrinfo: Temporary failure in name resolution
      raise if attempts > 5

      attempts += 1
      sleep 0.5
    end

    raise AlreadyLoggedInError if res.is_a? Net::HTTPSuccess

    URI(res['location'])
  end

  def self.discover_network
    require 'wifi_accessor/network_discover'

    WifiAccessor::NetworkDiscover.run
  end

  def self.run_hooks!(hooks, env, verbose: false **_)
    args = {}
    args[%i[out err]] = '/dev/null' unless verbose
    hooks&.each do |hook|
      cmd = hook
      if hook.is_a? Hash
        puts "- For hook #{cmd.inspect}"
        cmd = hook['hook']

        hook_if = hook['if']
        if hook_if
          print "   If #{hook_if.inspect} "
          if system(env, hook_if, args)
            puts 'succeeded.'
          else
            puts 'failed, skipping.'
            next
          end
        end

        hook_unless = hook['unless']
        if hook_unless
          print "  Unless #{hook_unless.inspect} "
          if system(env, hook_unless, args)
            puts 'succeeded, skipping.'
            next
          else
            puts 'failed.'
          end
        end
        puts "  Running hook #{cmd.inspect}"
      else
        puts "- Running hook #{cmd.inspect}"
      end

      next unless system(env, cmd, args)
      break if hook.is_a?(Hash) && hook['final']
    end
  end
end
