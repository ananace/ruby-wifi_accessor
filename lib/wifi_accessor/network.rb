# frozen_string_literal: true

module WifiAccessor
  class Network
    attr_accessor :name, :login, :data
    attr_reader :hooks
    attr_writer :url

    def initialize(name:, login:, data: nil, url: nil, hooks: {}, **_)
      @name = name
      @login = login
      @data = data
      @url = url
      @hooks = hooks
    end

    def data?
      !@data.nil?
    end

    def url
      @url || WifiAccessor.discover!
    end

    def login!
      return unless login

      dev = WifiAccessor.dev
      attempts = 0
      loop do
        begin
          puts "Attempting to reach #{url}"
          dev.visit url
          break
        rescue Capybara::Poltergeist::StatusFailError => ex
          raise if attempts > 5
          puts "#{ex.class}: #{ex}"
          attempts += 1
          sleep 0.5
        end
      end

      login.each do |entry|
        element = nil
        loop do
          name = case entry.class.to_s
                 when 'Hash'
                   entry.keys.first
                 when 'String'
                   entry
                 else
                   puts "Found entry #{entry.inspect} (#{entry.class.inspect})"
                   raise 'Unknown entry in login chain'
                 end

          begin
            # puts "Searching for #{name.inspect}"
            element = dev.find name
            # puts "Found element #{element.inspect}"
            break
          rescue Capybara::ElementNotFound
            sleep 0.5
          end
        end

        case entry.class.to_s
        when 'Hash'
          element.set entry.values.first
          # puts "Setting #{element.inspect} to #{entry.values.first.inspect}"
        when 'String'
          element.click
          # puts "Clicked #{element.inspect}"
        end
      end

      sleep 4

      begin
        WifiAccessor.discover!
        false
      rescue WifiAccessor::AlreadyLoggedInError
        true
      end
    end

    def data!
      return Data.new unless data

      dev = WifiAccessor.dev
      dev.visit url

      components = {}
      data.each do |entry|
        element = nil
        loop do
          begin
            name = entry.first
            element = dev.find name
            break
          rescue Capybara::ElementNotFound
            sleep 0.5
          end
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
