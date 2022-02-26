# frozen_string_literal: true

RSpec.describe BrazilToYnab::PortoSeguro::Xls do
  subject do
    described_class.new(
      filepath: "spec/fixtures/Fatura20220225.xls",
      options: {
        "import-future" => import_future
      }
    ).get_transactions
  end

  let(:import_future) { false }

  it "loads transactions from XLS file" do
    expect(subject.count).to eq(15)

    expect(subject[0].amount).to eq "-1108.18"
    expect(subject[0].payee).to eq "LOJA X"
    expect(subject[0].memo).to eq "LOJA X 04/05"
    expect(subject[0].transaction_date).to eq Date.parse("2022-01-14")
    expect(subject[0].first_installment_date).to eq Date.parse("2021-10-14")
    expect(subject[0].account_name).to eq "PERSON 1"
    expect(subject[0].card_number).to eq "3113"
    expect(subject[0].id).to eq "311320211014-1108180405LOJAX0405"

    expect(subject[1].amount).to eq "1000.0"
    expect(subject[1].payee).to eq "PIX"
    expect(subject[1].transaction_date).to eq Date.parse("2022-01-13")
    expect(subject[1].first_installment_date).to eq Date.parse("2022-01-13")
    expect(subject[1].account_name).to eq "PERSON 1"
    expect(subject[1].card_number).to eq "3113"
    expect(subject[1].id).to eq "311320220113100000101PIX"

    expect(subject[2].amount).to eq "-300.0"
    expect(subject[2].payee).to eq "RESTAURANTE BR"
    expect(subject[2].transaction_date).to eq Date.parse("2022-01-13")
    expect(subject[2].account_name).to eq "PERSON 1"
    expect(subject[2].card_number).to eq "3113"

    expect(subject[3].amount).to eq "-92.99"
    expect(subject[3].payee).to eq "AUTHENTIC FEET"
    expect(subject[3].memo).to eq "AUTHENTIC FEET 09/10"
    expect(subject[3].transaction_date).to eq Date.parse("2022-01-11")
    expect(subject[3].first_installment_date).to eq Date.parse("2021-05-11")
    expect(subject[3].account_name).to eq "PERSON 2"
    expect(subject[3].card_number).to eq "6230"
    expect(subject[3].id).to eq "623020210511-92990910AUTHENTICFEET0910"

    expect(subject[14].amount).to eq "-205.59"
    expect(subject[14].payee).to eq "PARC=108AIRBNB PAGA"
    expect(subject[14].memo).to eq "PARC=108AIRBNB PAGA 04/08"
    expect(subject[14].transaction_date).to eq Date.parse("2022-01-12")
    expect(subject[14].first_installment_date).to eq Date.parse("2021-10-12")
    expect(subject[14].account_name).to eq "PERSON 1"
    expect(subject[14].card_number).to eq "3311"
  end

  context "when importing future transactions" do
    let(:import_future) { true }

    it "generates more transactions" do
      expect(subject.count).to eq 21

      purchase_1 = subject.select { |s| s.memo =~ /LOJA X [0-9]{2}\/05/ }
      expect(purchase_1.count).to eq 2

      expect(purchase_1.map(&:payee).uniq).to eq ["LOJA X"]
      expect(purchase_1.map(&:amount).uniq).to eq ["-1108.18"]
      expect(purchase_1.map(&:first_installment_date).uniq).to eq [Date.parse("2021-10-14")]
      expect(purchase_1.map(&:account_name).uniq).to eq ["PERSON 1"]
      expect(purchase_1.map(&:card_number).uniq).to eq ["3113"]

      expect(purchase_1[0].memo).to eq "LOJA X 04/05"
      expect(purchase_1[0].transaction_date).to eq Date.parse("2022-01-14")
      expect(purchase_1[0].id).to eq "311320211014-1108180405LOJAX0405"

      expect(purchase_1[1].memo).to eq "LOJA X 05/05"
      expect(purchase_1[1].transaction_date).to eq Date.parse("2022-02-14")
      expect(purchase_1[1].id).to eq "311320211014-1108180505LOJAX0505"
    end
  end

  context "when file has no date on its name" do
    subject do
      # mtime for this file: 2022-02-12 19:30:22
      described_class
        .new(filepath: "spec/fixtures/Fatura00000000.xls")
        .get_transactions
    end

    it "uses the file's modification time" do
      expect(subject[0].amount).to eq "-1108.18"
      expect(subject[0].payee).to eq "LOJA X"
      expect(subject[0].memo).to eq "LOJA X 04/05"
      expect(subject[0].transaction_date).to eq Date.parse("2022-01-14")
      expect(subject[0].first_installment_date).to eq Date.parse("2021-10-14")
      expect(subject[0].account_name).to eq "PERSON 1"
      expect(subject[0].card_number).to eq "3113"
      expect(subject[0].id).to eq "311320211014-1108180405LOJAX0405"

      expect(subject[1].amount).to eq "1000.0"
      expect(subject[1].payee).to eq "PIX"
      expect(subject[1].transaction_date).to eq Date.parse("2022-01-13")
      expect(subject[1].first_installment_date).to eq Date.parse("2022-01-13")
      expect(subject[1].account_name).to eq "PERSON 1"
      expect(subject[1].card_number).to eq "3113"
      expect(subject[1].id).to eq "311320220113100000101PIX"

      expect(subject[2].amount).to eq "-300.0"
      expect(subject[2].payee).to eq "RESTAURANTE BR"
      expect(subject[2].transaction_date).to eq Date.parse("2022-01-13")
      expect(subject[2].account_name).to eq "PERSON 1"
      expect(subject[2].card_number).to eq "3113"

      expect(subject[3].amount).to eq "-92.99"
      expect(subject[3].payee).to eq "AUTHENTIC FEET"
      expect(subject[3].memo).to eq "AUTHENTIC FEET 09/10"
      expect(subject[3].transaction_date).to eq Date.parse("2022-01-11")
      expect(subject[3].first_installment_date).to eq Date.parse("2021-05-11")
      expect(subject[3].account_name).to eq "PERSON 2"
      expect(subject[3].card_number).to eq "6230"
      expect(subject[3].id).to eq "623020210511-92990910AUTHENTICFEET0910"

      expect(subject[14].amount).to eq "-205.59"
      expect(subject[14].payee).to eq "PARC=108AIRBNB PAGA"
      expect(subject[14].memo).to eq "PARC=108AIRBNB PAGA 04/08"
      expect(subject[14].transaction_date).to eq Date.parse("2022-01-12")
      expect(subject[14].first_installment_date).to eq Date.parse("2021-10-12")
      expect(subject[14].account_name).to eq "PERSON 1"
      expect(subject[14].card_number).to eq "3311"
    end
  end
end
