# frozen_string_literal: true

RSpec.describe BrazilToYnab::Ynab::Milliunit do
  subject do
  end

  it "loads transactions from XLS file" do
    expect(described_class.new(100).format).to eq 1000
    expect(described_class.new(100.8).format).to eq 100800
    expect(described_class.new("100.80").format).to eq 100800
    expect(described_class.new("-100.80").format).to eq -100800
  end
end
