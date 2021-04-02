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
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end

    raise AlreadyLoggedInError if res.is_a? Net::HTTPSuccess

    URI(res['location'])
  end
end
