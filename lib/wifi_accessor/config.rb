module WifiAccessor
  class Config
    def self.load!
      networks = []
      data_path = '~/.config/wifi.yml'
      data_path = "#{ENV['XDG_CONFIG_HOME']}/wifi.yml" if ENV['XDG_CONFIG_HOME']

      file = Psych.load open(File.expand_path(data_path))
      Config.new file
    end

    def get(name)
      @networks.find { |n| n.name == name }
    end

    private

    def initialize(config)
      @networks = []
      @global = {
        'error' => {}
      }

      config.each do |network, data|
        if network == '_global'
          @global.merge! data
          next
        end

        params = {
          name: network
        }.merge(data.transform_keys(&:to_sym))

        if params.key?(:hooks) || !@global.empty?
          params[:hooks] ||= {}
          @global.dig('hooks').each do |hook, data|
            stored = params[:hooks][hook] ||= []
            params[:hooks][hook] = data + stored
          end
        end

        @networks << Network.new(**params)
      end
    end
  end
end
