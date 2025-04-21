# frozen_string_literal: true

require "ynab"

module BrazilToYnab
  class Ynab
    def initialize(options:)
      @options = options
    end

    def list_budgets
      budget_response = client.budgets.get_budgets
      budget_response.data.budgets
    end

    def list_accounts(budget_id)
      response = client.accounts.get_accounts(budget_id)
      response.data.accounts
    end

    def sync(xls_file:)
      @errors = []

      transactions =
        BrazilToYnab::PortoSeguro::Xls
          .new(filepath: xls_file, options: @options)
          .get_transactions
          .map { |transaction| Ynab::Transaction.new(transaction, @errors) }
          .compact

      return if transactions.none?

      transactions =
        transactions
        .select { |txn| txn.in_the_past? }
      puts "Transactions for posting: #{transactions.count}"

      response = client
        .transactions
        .create_transaction(budget_id, transactions: transactions.map(&:payload))

      # For the duplicates, let's update them but,
      #
      # - without changing their payee because they can be edited in
      #   YNAB
      # - without changing their description for the same reason
      duplicate_ids = response.data.duplicate_import_ids

      if duplicate_ids.any?
        duplicate_transactions =
          transactions.select { |txn| duplicate_ids.include?(txn.import_id) }

        puts "Duplicate transactions: #{duplicate_transactions.count}"

        update_duplicates(duplicate_transactions)
      else
        puts "No duplicate transactions"
      end
    rescue ::YNAB::ApiError => e
      # The API returns an error that looks like this:
      #
      # e.id=400
      # e.name=bad_request
      # e.detail="transaction does not exist in this budget (index: 0), " +
      #          "transaction does not exist in this budget (index: 1), " +
      #          "transaction does not exist in this budget (index: 2)"
      #
      # We extract those indexes, and output only those transactions.

      errored_indexes = e.detail.scan(/\(index: (\d+)\)/).flatten.map(&:to_i)

      transactions.each_with_index do |txn, index|
        if errored_indexes.include?(index)
          puts "Transaction #{index}: #{txn.payload.inspect}" 
        end
      end

      puts "YNAB ERROR: id=#{e.id}; name=#{e.name}; detail: #{e.detail}"
    ensure
      errors = @errors.compact.uniq
      puts "@errors: #{errors.count}"
      errors.each do |error|
        puts error
      end
    end

    private

    def client
      @client ||= ::YNAB::API.new(ENV["YNAB_ACCESS_TOKEN"])
    end

    def budget_id
      ENV[EnvVars::BUDGET] ||
        raise("You have not defined #{EnvVars::BUDGET}")
    end

    # We'll reload the transactions from their API so we don't
    # override 'memo's that were already uploaded. We'll only
    def update_duplicates(existing_transactions)
      puts "Overriding all memos" if @options["override-memo"]

      new_payload =
        existing_transactions
          .map { |txn|
          exceptions = [:payee]
          exceptions << :memo unless @options["override-memo"]

          txn.payload.except(*exceptions)
        }

      client
        .transactions
        .update_transactions(budget_id, transactions: new_payload)
    end
  end
end
