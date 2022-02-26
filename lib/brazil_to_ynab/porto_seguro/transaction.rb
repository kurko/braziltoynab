# frozen_string_literal: true

module BrazilToYnab
  module PortoSeguro
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
          @card_number.tr("-", ""),
          # Always keep the original date, otherwise we might
          # risk hitting duplicates as we make the same purchases
          # again in the future (same day on the month, same number
          # of installments)
          first_installment_date.to_s.tr("-", ""),
          amount,
          installment_id,
          memo.tr("-", "")
        ].compact.join.tr("^A-Za-z0-9-", "")
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
          .gsub(/[0-9]{1,2}\/[0-9]{1,2}/, "")
          .gsub(/\s\s/, " ")
          .strip
      end

      def memo
        @payee
      end

      # e.g 02/10 (2nd payment out of 10)
      def installments_string
        installments_match[0] if installments?
      end

      def installments?
        !installments_match.nil?
      end

      private

      def current_installment
        return unless installments?
        installments_match[1].to_i
      end

      def installments_match
        @installments_match ||= memo.match(/([0-9]{1,2})\/[0-9]{1,2}/)
      end
    end
  end
end
