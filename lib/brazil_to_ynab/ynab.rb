# frozen_string_literal: true

require 'ynab'

module BrazilToYnab
  class Ynab
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
      ENV[EnvVars.card_account_id(card_number)]
    end

    def budget_id
      ENV[EnvVars::BUDGET] ||
        raise("You have not defined #{EnvVars::BUDGET}")
    end

    def payload_for_transaction(transaction)
      card_number = transaction.card_number

      if account_for_card(card_number).nil?
        message = "No account configuration for card #{card_number}. Define #{EnvVars.card_account_id(card_number)}"
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
