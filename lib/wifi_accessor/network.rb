# frozen_string_literal: true

module WifiAccessor
  class Network
    attr_accessor :name, :login, :data, :url
    attr_reader :hooks

    def initialize(name:, login:, **params)
      @name = name
      @login = login
      @data = params[:data]
      @url = params[:url]
      @hooks = params[:hooks]
    end

    def data?
      !@data.nil?
    end

    def login?
      !@login.nil?
    end

    def url
      @url || WifiAccessor.discover!
    end

    def login!
      return unless login?

      dev = WifiAccessor.dev
      attempts = 0
      loop do
        dev.visit url
        break
      rescue Capybara::Poltergeist::StatusFailError
        raise if attempts > 5

        attempts += 1
        sleep 0.1
      end

      login.each do |entry|
        attempts = 0
        element = nil
        loop do
          name = case entry.class.to_s
                 when 'Hash'
                   entry.keys.first
                 when 'String'
                   entry
                 else
                   raise 'Unknown entry in login chain'
                 end

          begin
            element = dev.find name
            break
          rescue Capybara::ElementNotFound
            raise if attempts > 5

            attempts += 1
            sleep 0.25
          end
        end

        case entry.class.to_s
        when 'Hash'
          element.set entry.values.first
        when 'String'
          element.click
        end
      end

      true
    end

    def data!
      return Data.new unless data

      dev = WifiAccessor.dev
      dev.visit url

      components = {}
      data.each do |entry|
        element = nil
        attempts = 0
        loop do
          name = entry.first
          element = dev.find name
          break
        rescue Capybara::ElementNotFound
          raise if attempts > 5

          attempts += 1
          sleep 0.25
        end

        rex = Regexp.new entry.last
        match = rex.match(element.text)

        components.merge(Hash[match.names.map(&:to_sym).zip(match.captures)]) unless match.nil?
      end

      return Data.new(**components) unless components.nil?

      Data.new
    end
  end
end
