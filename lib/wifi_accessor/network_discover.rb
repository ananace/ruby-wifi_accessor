# frozen_string_literal: true

module DBus
  class Service
    def dig(*args)
      ptr = self
      args.each do |arg|
        ptr = ptr[arg]
        return nil if ptr.nil?
      end
      ptr
    end
  end
end

module WifiAccessor
  class NetworkDiscover
    def self.run
      disc = new

      network = disc.networkmanager
      network ||= disc.iwconfig
      network
    end

    NM_SVC = 'org.freedesktop.NetworkManager'
    NM_OBJ = '/org/freedesktop/NetworkManager'
    NM_IFACE = NM_SVC

    NM_CONN_IFACE = 'org.freedesktop.NetworkManager.Connection.Active'

    def networkmanager
      require 'dbus'

      bus = DBus.system_bus
      nm_svc = bus[NM_SVC]
      nm_svc
        .dig(NM_OBJ, NM_IFACE, 'ActiveConnections')
        .map { |path| nm_svc.dig(path, NM_CONN_IFACE) }
        .select { |conn| conn['Type'].include? 'wireless' }
        .map { |conn| conn['Id'] }
        .first
    rescue LoadError
      nil
    end

    def iwconfig
      nil
    end
  end
end
