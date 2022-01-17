# frozen_string_literal: true

module BrazilToYnab
  class Transaction
    class Error < StandardError; end

    attr_reader :account_name, :card_number

    def initialize(credit:, debit:, payee:, date:, account_name:, card_number:)
      @credit = credit&.to_s&.strip
      @debit = debit&.to_s&.strip
      @payee = payee&.strip
      @date = date
      @account_name = account_name&.strip
      @card_number = card_number&.strip
    end

    def id
      installment_id = if installments?
                         installments_string
                       else
                         "01/01"
                       end

      [
        @card_number.tr('-', ''),
        transaction_date.to_s.tr('-', ''),
        amount,
        installment_id,
        memo.tr('-', ''),
      ].join.tr('^A-Za-z0-9-', '')
    end

    def transaction_date
      return @date unless installments?

      @date.next_month(current_installment - 1)
    end

    def first_installment_date
      @date
    end

    def amount
      if @credit.to_i != 0
        @credit.to_f.abs.to_s
      elsif @debit.to_i != 0
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

    private

    def installments?
      !installments_string.nil?
    end

    def current_installment
      return unless installments?
      installments_string[1].to_i
    end

    def installments_string
      memo.match(/([0-9]{1,2})\/[0-9]{1,2}/)
    end
  end
end
