# frozen_string_literal: true

require_relative "ynab/version"
require 'portoseguro/transaction'
require 'roo-xls'

module Portoseguro
  class Xls
    HEADER_ROW = 1

    CARD_NAME_COL = 1
    DATE_COL = 1
    DESCRIPTION_COL = 2
    CREDIT_COL = 3
    DEBIT_COL = 4
    CARD_NUMBER_COL = 5

    TOTAL_CELL_VALUE = "TOTAL".freeze
    NATIONAL_SHEET = "nacional"


    def initialize(file:)
      @file = file
    end

    def get_transactions
      row = HEADER_ROW + 1
      cel = 1
      transactions = []
      current_card = nil
      current_card_name = nil

      while !xls.cell(row, cel).nil?
        if cell(row, CARD_NUMBER_COL)
          current_card = cell(row, CARD_NUMBER_COL)
          current_card_name = cell(row, CARD_NAME_COL)
        end

        if transaction?(row)
          transactions << Portoseguro::Transaction.new(
            card_number: current_card,
            account_name: current_card_name,
            date: transaction_date(cell(row, DATE_COL)),
            payee: cell(row, DESCRIPTION_COL),
            credit: cell(row, CREDIT_COL),
            debit: cell(row, DEBIT_COL),
          )
        end

        row += 1
      end

      transactions
    end

    private

    def xls
      @xls ||= ::Roo::Excel.new(@file)
    end

    def cell(row, col, sheet = NATIONAL_SHEET)
      xls.cell(row, col, NATIONAL_SHEET)
    end

    def transaction?(row)
      row != HEADER_ROW &&
        xls.cell(row, 1) != TOTAL_CELL_VALUE &&
        !xls.cell(row, DESCRIPTION_COL).nil? &&
        (
          xls.cell(row, CREDIT_COL) ||
          xls.cell(row, DEBIT_COL)
        )
    end

    def transaction_date(day_month)
      file_match = @file.match('([0-9]{4})([0-9]{2})')
      file_year, file_month = file_match[1], file_match[2]

      transaction_day = day_month.split('/').first
      transaction_month = day_month.split('/').last

      if transaction_month.to_i > file_month.to_i
        file_year = (file_year.to_i - 1).to_s
      end

      [file_year, transaction_month, transaction_day].join('-')
    end
  end
end
