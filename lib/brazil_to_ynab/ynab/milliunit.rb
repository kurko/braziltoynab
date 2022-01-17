# frozen_string_literal: true

module BrazilToYnab
  class Ynab
    class Milliunit
      def initialize(amount)
        @amount = amount
      end

      def format
        amount = @amount.to_s
        amount_with_two_decimals = amount.gsub(/\.([0-9]{1})\Z/, '\10')
        int_amount = amount_with_two_decimals.gsub(/[,.]/, '')
        "#{int_amount}0".to_i
      end
    end
  end
end
