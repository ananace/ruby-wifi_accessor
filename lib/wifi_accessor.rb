# frozen_string_literal: true

require 'capybara'
require 'capybara/poltergeist'
require 'wifi_accessor/data'
require 'wifi_accessor/network'
require 'wifi_accessor/version'

module WifiAccessor
  class AlreadyLoggedInError < StandardError; end
  class Error < StandardError; end

  TEST_URI = URI('http://example.com').freeze

  def self.access_login(net)
    return ArgumentError, 'Unknown network' unless net.is_a? Network

  end

  def self.dev
    @dev ||= Capybara::Session.new :poltergeist
  end

  def self.data
    @data ||= begin
      ret = []
      file = Psych.load open(File.expand_path('~/.config/wifi.yml'))
      file.each do |url, data|
        next if url == '_global'

        params = {
          name: url
        }.merge(data.transform_keys(&:to_sym))

        if params.key?(:hooks) || file.key?('_global')
          params[:hooks] ||= {}
          file.dig('_global', 'hooks').each do |hook, data|
            stored = params[:hooks][hook] ||= []
            params[:hooks][hook] = data + stored
          end
        end

        ret << Network.new(**params)
      end
      ret.instance_eval do
        def get(name)
          find { |n| n.name == name }
        end
      end
      ret
    end
  end

  def self.discover!
    uri = TEST_URI.dup
    res = nil
    attempts = 0
    loop do
      begin
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end
        break
      rescue SocketError # getaddrinfo: Temporary failure in name resolution
        raise if attempts > 4
        attempts += 1
        sleep 0.5
      end
    end

    raise AlreadyLoggedInError if res.is_a? Net::HTTPSuccess

    URI(res['location'])
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
          unless system(env, hook_if, args)
            puts "failed, skipping."
            next
          else
            puts "succeeded."
          end
        end

        hook_unless = hook['unless']
        if hook_unless
          print "  Unless #{hook_unless.inspect} "
          if system(env, hook_unless, args)
            puts "failed, skipping."
            next
          else
            puts "succeeded."
          end
        end
        puts "  Running hook #{cmd.inspect}"
      else
        puts "- Running hook #{cmd.inspect}"
      end

      next unless system(env, cmd, args)

      if hook.is_a? Hash
        break if hook['final']
      end
    end
  end
end
