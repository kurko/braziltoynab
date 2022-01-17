# frozen_string_literal: true

RSpec.describe Portoseguro::Ynab do
  subject do
    described_class.new(file: 'Fature20220225.xls')
  end

  it "loads transactions from XLS file" do
    subject.list_budgets
  end
end
