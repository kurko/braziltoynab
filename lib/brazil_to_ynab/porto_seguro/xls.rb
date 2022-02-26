# BrazilToYnab frozen_string_literal: true

module BrazilToYnab
  module PortoSeguro
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

      class UndefinedRelativeDate < StandardError; end

      # Params
      #
      # - filepath: this is a path to the XLS file we want to import.
      #
      # The filename must follow the format `fatura20220202.xls` otherwise we
      # don't know what the statement date is. The XLS file doesn't include any
      # information about what year each transaction happens. If there's no
      # date in the name, we fallback to File#mtime.
      #
      # So if today is january first and you see 29/12, it's 3 days ago. But if
      # you see 01/06, you don't know if it's a future installment or the
      # initial date of the purchase (first installment 6 months ago).
      #
      # The file has this format:
      #
      #   |           |                        | Crédito | Débito | Cartão |
      #   | John Doe                           |         |        | 1234   |
      #   | 10/01     | 01/03 Shampoo          |         |        |        |
      #   | 11/01     | Some description       |         |        |        |
      #   | Mary Doe                           |         |        | 2345   |
      #   | 12/12     | 02/12 Some description |         |        |        |
      #   | 13/01     | Some description       |         |        |        |
      #
      # The date refers to the moment of the purchase. Above, purchase `12/12`
      # is when the first installment took place. The description `02/03`  means
      # it's the 2nd installment now, which is being charged on january 12th.
      # Throughout the whole 12 installments, the date will never change.
      #
      def initialize(filepath:)
        @filepath = filepath
        if @filepath.nil?
          raise ".xls file path is not defined"
        end
      end

      def get_transactions
        validate_file_has_year_month

        row = HEADER_ROW + 1
        cel = 1
        transactions = []
        current_card = nil
        current_card_name = nil

        until xls.cell(row, cel).nil?
          if cell(row, CARD_NUMBER_COL)
            current_card = cell(row, CARD_NUMBER_COL)
            current_card_name = cell(row, CARD_NAME_COL)
          end

          if transaction?(row)
            transactions << BrazilToYnab::PortoSeguro::Transaction.new(
              card_number: current_card,
              account_name: current_card_name,
              date: first_installment_date(cell(row, DATE_COL)),
              payee: cell(row, DESCRIPTION_COL),
              credit: cell(row, CREDIT_COL),
              debit: cell(row, DEBIT_COL)
            )
          end

          row += 1
        end

        transactions
      end

      private

      def xls
        @xls ||= ::Roo::Excel.new(@filepath)
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

      # Porto Seguro shows the date the transaction was created (without the
      # year).  If you bought in january and now you're on the 5th installment,
      # this date continues being january, but the description shows `05/10`
      # (5th installment out of 10).
      def first_installment_date(day_month)
        file_year, file_month =
          file_or_statement_date.year, file_or_statement_date.month

        transaction_day = day_month.split("/").first
        transaction_month = day_month.split("/").last

        if transaction_month.to_i > file_month.to_i
          file_year = (file_year.to_i - 1).to_s
        end

        Date.new(file_year.to_i, transaction_month.to_i, transaction_day.to_i)
      end

      def validate_file_has_year_month
        return if file_or_statement_date

        raise UndefinedRelativeDate, "No date found for #{@filepath}"
      end

      def file_or_statement_date
        filename_date_match = @filepath.match("Fatura([0-9]{4})([0-9]{2})([0-9]{2})")
        if filename_date_match[1].to_i > Date.today.year - 10 &&
            filename_date_match[2].to_i.between?(1, 12)
          Time.new(
            filename_date_match[1],
            filename_date_match[2],
            10 # We don't care about the file day nor time.
          )
        else
          File.new(@filepath).mtime
        end
      end
    end
  end
end
