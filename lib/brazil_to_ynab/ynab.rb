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

      BrazilToYnab::PortoSeguro::Xls.new(file: xls_file).get_transactions.each do |transaction|
        begin
          if create_transaction(transaction)
            print "."
          end
        rescue ::YNAB::ApiError => e
          # If a transaction already exists, nevermind.
          unless e.name == 'conflict'
            raise e
          end
        end
      end
      puts ""
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
      ENV["PORTOSEGURO_YNAB_#{card_number}"]
    end

    def budget_id
      constant = 'PORTOSEGURO_YNAB_BUDGET'
      ENV[constant] ||
        raise("You have not defined #{constant}")
    end

    def create_transaction(transaction)
      if account_for_card(transaction.card_number).nil?
        @error_messages["No account configuration for card #{transaction.card_number}"] = nil
        return
      end

      input = {
        account_id: account_for_card(transaction.card_number),
        amount: BrazilToYnab::Ynab::Milliunit.new(transaction.amount).format,
        date: transaction.date,
        payee_name: transaction.payee,
        memo: transaction.memo,
        import_id: transaction.id.to_s[0..35],
      }

      client.transactions.create_transaction(budget_id, transaction: input)
    end
  end
end
