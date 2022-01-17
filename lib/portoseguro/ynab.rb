# frozen_string_literal: true

require 'ynab'

module Portoseguro
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
      Portoseguro::Xls.new(file: xls_file).get_transactions.each do |transaction|
        begin
          create_transaction(transaction)
        rescue YNAB::ApiError => e
          unless e.name == 'conflict'
            raise e
          end
        end
      end
    rescue YNAB::ApiError => e
      puts "ERROR: id=#{e.id}; name=#{e.name}; detail: #{e.detail}"
    end

    private

    def client
      @client ||= YNAB::API.new(ENV['YNAB_ACCESS_TOKEN'])
    end

    def account_for_card(card_number)
      ENV["PORTOSEGURO_YNAB_#{card_number}"]
    end

    def budget_id
      constant = 'PORTOSEGURO_YNAB_BUDGET'
      ENV[constant] ||
        raise("You have not defined #{constant}")
    end

    def create_transaction(transaction)
      return if account_for_card(transaction.card_number).nil?

      input = {
        account_id: account_for_card(transaction.card_number),
        amount: Portoseguro::Ynab::Milliunit.new(transaction.amount).format,
        date: transaction.date,
        payee_name: transaction.payee,
        memo: transaction.memo,
        import_id: transaction.id.to_s[0..35],
      }

      puts input
      puts budget_id
      client.transactions.create_transaction(budget_id, transaction: input)
    end
  end
end
