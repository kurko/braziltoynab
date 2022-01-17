# frozen_string_literal: true

module BrazilToYnab
  class Transaction
    class Error < StandardError; end

    attr_reader :account_name, :card_number, :date

    def initialize(credit:, debit:, payee:, date:, account_name:, card_number:)
      @credit = credit&.to_s&.strip
      @debit = debit&.to_s&.strip
      @payee = payee&.strip
      @date = date&.strip
      @account_name = account_name&.strip
      @card_number = card_number&.strip
    end

    def id
      "#{@date}#{@card_number}#{amount}#{memo}".tr('^A-Za-z0-9', '')
    end

    def amount
      if @credit
        @credit
      elsif @debit
        "-#{@debit}"
      else
        raise Error, "No credit nor debit found"
      end
    end

    def payee
      @payee
        .gsub(/[0-9]{1,2}\/[0-9]{1,2}/, '')
        .gsub(/\s\s/, ' ')
        .strip
    end

    def memo
      @payee
    end
  end
end
