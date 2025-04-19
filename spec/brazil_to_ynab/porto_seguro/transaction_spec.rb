# frozen_string_literal: true

require "spec_helper"

RSpec.describe BrazilToYnab::PortoSeguro::Transaction do
  subject do
    described_class.new(
      card_number: "1234",
      credit: credit,
      debit: 0,
      payee: payee,
      date: Date.new(2021, 10, 10),
      account_name: ""
    )
  end

  let(:credit) { 10 }
  let(:payee) { "Payee" }

  it_behaves_like "transaction"

  describe "different amounts" do
    let(:credit) { 0.25 }

    it { expect(subject.amount).to eq "0.25" }
  end

  describe "installments" do
    context "when no installments defined" do
      let(:payee) { "Payee" }

      it { expect(subject.total_installments).to eq 1 }
      it { expect(subject.current_installment).to eq 1 }
      it { expect(subject.future_installments?).to eq false }
    end

    context "when one installment" do
      let(:payee) { "Payee 01/01" }

      it { expect(subject.total_installments).to eq 1 }
      it { expect(subject.current_installment).to eq 1 }
      it { expect(subject.future_installments?).to eq false }
    end

    context "when 4 installments, 1st transaction" do
      let(:payee) { "Payee 01/04" }

      it { expect(subject.total_installments).to eq 4 }
      it { expect(subject.current_installment).to eq 1 }
      it { expect(subject.future_installments?).to eq true }
    end

    context "when 4 installments, 2nd transaction" do
      let(:payee) { "Payee 02/04" }

      it { expect(subject.total_installments).to eq 4 }
      it { expect(subject.current_installment).to eq 2 }
      it { expect(subject.future_installments?).to eq true }
    end

    context "when 12 installments, 3rd transaction" do
      let(:payee) { "Payee 03/12" }

      it { expect(subject.total_installments).to eq 12 }
      it { expect(subject.current_installment).to eq 3 }
      it { expect(subject.future_installments?).to eq true }
    end

    context "when 12 installments, 11th transaction" do
      let(:payee) { "Payee 11/12" }

      it { expect(subject.total_installments).to eq 12 }
      it { expect(subject.current_installment).to eq 11 }
      it { expect(subject.future_installments?).to eq true }
    end

    context "when 12 installments, 12th transaction" do
      let(:payee) { "Payee 12/12" }

      it { expect(subject.total_installments).to eq 12 }
      it { expect(subject.current_installment).to eq 12 }
      it { expect(subject.future_installments?).to eq false }
    end
  end
end
