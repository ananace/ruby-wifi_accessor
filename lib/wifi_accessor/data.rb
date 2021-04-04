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
        total.nil? && @available.nil?
      end

      def available
        return @available unless @available.nil?
        return (@total - @used) unless @total.nil? || @used.nil?
      end
    end
  end
end
