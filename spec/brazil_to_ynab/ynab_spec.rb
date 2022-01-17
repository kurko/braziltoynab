# frozen_string_literal: true

RSpec.describe BrazilToYnab::Ynab do
  subject do
    described_class.new
  end

  it "loads transactions from XLS file" do
    subject.list_budgets
  end
end
