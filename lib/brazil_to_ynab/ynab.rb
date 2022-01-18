# frozen_string_literal: true

require 'ynab'

module BrazilToYnab
  class Ynab
    # This is called PORTOSEGURO but the source could be other banks.
    # Given we only support one for now, I'll keep it as is. The #sync
    # method will also need to load these vars conditionally.
    BUDGET_ENV_VAR = "BRAZILTOYNAB_PORTOSEGURO_BUDGET".freeze
    CARD_ACCOUNT_ENV_VAR = "BRAZILTOYNAB_PORTOSEGURO".freeze

    def list_budgets
      budget_response = client.budgets.get_budgets
      budgets = budget_response.data.budgets
    end

    def list_accounts(budget_id)
      response = client.accounts.get_accounts(budget_id)
      response.data.accounts
    end

    def sync(xls_file:)
      @error_messages = {}

      payload =
        BrazilToYnab::PortoSeguro::Xls
        .new(file: xls_file)
        .get_transactions
        .map { |transaction| payload_for_transaction(transaction) }
        .compact

      return if payload.none?

      response = client
        .transactions
        .create_transaction(budget_id, transactions: payload)

      # For the duplicates, let's update them but,
      #
      # - without changing their payee because they can be edited in
      #   YNAB
      # - without changing their description for the same reason
      duplicate_ids = response.data.duplicate_import_ids

      if duplicate_ids.any?
        new_payload =
          payload
          .select { |txn| duplicate_ids.include?(txn[:import_id]) }
          .map { |txn| txn.except(:payee, :memo) }

        client
          .transactions
          .update_transactions(budget_id, transactions: new_payload)
      end

    rescue ::YNAB::ApiError => e
      puts "YNAB ERROR: id=#{e.id}; name=#{e.name}; detail: #{e.detail}"
    ensure
      @error_messages.each do |key, value|
        puts key
      end
    end

    private

    def client
      @client ||= ::YNAB::API.new(ENV['YNAB_ACCESS_TOKEN'])
    end

    def account_for_card(card_number)
      ENV["#{CARD_ACCOUNT_ENV_VAR}_#{card_number}"]
    end

    def budget_id
      ENV[BrazilToYnab::Ynab::BUDGET_ENV_VAR] ||
        raise("You have not defined #{BrazilToYnab::Ynab::BUDGET_ENV_VAR}")
    end

    def payload_for_transaction(transaction)
      card_number = transaction.card_number

      if account_for_card(card_number).nil?
        message = "No account configuration for card #{card_number}. Define #{CARD_ACCOUNT_ENV_VAR}_#{card_number}"
        @error_messages[message] = nil
        return
      end

      transaction_date = transaction.transaction_date.strftime("%Y-%m-%d")
      {
        account_id: account_for_card(card_number),
        amount: BrazilToYnab::Ynab::Milliunit.new(transaction.amount).format,
        date: transaction_date,
        payee_name: transaction.payee,
        memo: transaction.memo,
        import_id: transaction.id.to_s[0..34],
      }
    end
  end
end
