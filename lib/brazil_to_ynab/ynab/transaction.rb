# frozen_string_literal: true

module BrazilToYnab
  class Ynab
    class Transaction
      class Error < StandardError; end

      # Beware: changing this version will cause all transactions to
      # be recreated. Only use this for testing.
      VERSION = 1

      # Params:
      #
      # - transaction: a generic transaction that respects
      #   specs/contracts/transaction, such as PortoSeguro::Transaction
      def initialize(transaction, errors = [])
        @transaction = transaction
        @errors = errors
      end

      def payload
        card_number = @transaction.card_number

        if account_for_card.nil?
          @errors << "No account configuration for card #{card_number}. Define #{EnvVars.card_account_id(card_number)}"
          return
        end

        {
          account_id: account_for_card,
          amount: BrazilToYnab::Ynab::Milliunit.new(@transaction.amount).format,
          date: transaction_date,
          payee_name: @transaction.payee,
          memo: memo,
          import_id: import_id
        }
      end

      def import_id
        id = "#{VERSION}#{@transaction.id}"
        id[0..35]
      end

      def account_for_card
        @account_for_card ||= ENV[EnvVars.card_account_id(@transaction.card_number)]
      end

      private

      def memo
        text = []
        text << ENV[EnvVars.memo_prefix(@transaction.card_number)]
        text << "#{@transaction.installments_string} " if @transaction.installments?

        original_memo = @transaction.memo
        original_memo.sub!(@transaction.installments_string, "") if @transaction.installments?
        text << original_memo
        text.compact.join
      end

      def transaction_date
        @transaction.transaction_date.strftime("%Y-%m-%d")
      end
    end
  end
end
