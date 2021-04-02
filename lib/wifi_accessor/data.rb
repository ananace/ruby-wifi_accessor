# frozen_string_literal: true

module WifiAccessor
  class Network
    class Data
      attr_reader :used, :total

      def initialize(avail: nil, used: nil, total: nil)
        @available = avail
        @used = used
        @total = total
      end

      def infinite?
        total.nil? && avail.nil?
      end

      def available
        @available || (@total - @used)
      end
    end
  end
end
