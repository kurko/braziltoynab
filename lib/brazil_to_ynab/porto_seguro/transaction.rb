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

      # This is later used as idempotency key for YNAB (import_id)
      def id
        installment_id = if installments?
          installments_string
        else
          "01/01"
        end

        values = [
          @card_number.tr("-", ""),
          # Always keep the original date, otherwise we might
          # risk hitting duplicates as we make the same purchases
          # again in the future (same day on the month, same number
          # of installments)
          first_installment_date.to_s.tr("-", ""),
          amount,
          installment_id,

          # The memo can change between statements, so we only keep the first
          # 4 characters of the memo. On analysis, it looks like it never
          # changes the first few characters, so this is a good compromise.
          #
          # For example, 'APPLE.COM/BILL' and then later the same purchase
          # is described as 'APPLE.COM/BILLSAOPAULO'. In this example, the
          # memo was made _more detailed_, but the memo can also change completely,
          # like 'UBER*PENDING' and then later 'UBER*SAOPAULO' for the
          # purchase.
          #
          # Example:
          #
          # 'APPLE.COM/BILL' -> 'APPL'
          # 'UBER*PENDING'   -> 'UBER'
          # 'ASA*DIFFER'     -> 'ASA*'
          #
          # We also remove any non-alphanumeric characters, to avoid
          # having special characters in the id.
          memo.tr("-", "")[0..3]
        ].compact.join

        values.tr("^A-Za-z0-9-", "")
      end

      def transaction_date
        return @date unless installments?

        @date.next_month(current_installment - 1)
      end

      def amount
        # Porto Seguro will return random `-` symbols for credit and debit, so
        # we need to convert to abs to check if the value is present, and also
        # remove any symbols for credit (we distinguish credit and debit to
        # be intentional about sign).
        if @credit.to_f.abs > 0
          @credit.to_f.abs.to_s.delete("-")
        elsif @debit.to_f.abs > 0
          "-#{@debit}"
        else
          raise(
            Error,
            "No credit nor debit found for transaction: #{@payee} on #{@date}"
          )
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

      def first_installment_date
        @date
      end

      def total_installments
        return 1 unless installments?
        installments_match[2].to_i
      end

      def current_installment
        return 1 unless installments?
        installments_match[1].to_i
      end

      def future_installments?
        current_installment < total_installments
      end

      private

      # The memo is something like "Some Shop Name 02/04" (2nd payment out of 4)
      def installments_match
        @installments_match ||= memo.match(/([0-9]{1,2})\/([0-9]{1,2})/)
      end
    end
  end
end
