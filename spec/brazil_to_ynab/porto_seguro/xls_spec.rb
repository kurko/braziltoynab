# frozen_string_literal: true

RSpec.describe BrazilToYnab::PortoSeguro::Xls do
  subject do
    described_class.new(file: 'Fature20220225.xls').get_transactions
  end

  it "loads transactions from XLS file" do

    expect(subject[0].amount).to eq '-1108.18'
    expect(subject[0].payee).to eq 'LOJA X'
    expect(subject[0].memo).to eq 'LOJA X 04/05'
    expect(subject[0].transaction_date).to eq Date.parse('2022-01-14')
    expect(subject[0].first_installment_date).to eq Date.parse('2021-10-14')
    expect(subject[0].account_name).to eq 'PERSON 1'
    expect(subject[0].card_number).to eq '3113'
    expect(subject[0].id).to eq '311320220114-1108180405LOJAX0405'

    expect(subject[1].amount).to eq '1000.0'
    expect(subject[1].payee).to eq 'PIX'
    expect(subject[1].transaction_date).to eq Date.parse('2022-01-13')
    expect(subject[1].first_installment_date).to eq Date.parse('2022-01-13')
    expect(subject[1].account_name).to eq 'PERSON 1'
    expect(subject[1].card_number).to eq '3113'
    expect(subject[1].id).to eq '311320220113100000101PIX'

    expect(subject[2].amount).to eq '-300.0'
    expect(subject[2].payee).to eq 'RESTAURANTE BR'
    expect(subject[2].transaction_date).to eq Date.parse('2022-01-13')
    expect(subject[2].account_name).to eq 'PERSON 1'
    expect(subject[2].card_number).to eq '3113'

    expect(subject[3].amount).to eq '-92.99'
    expect(subject[3].payee).to eq 'AUTHENTIC FEET'
    expect(subject[3].memo).to eq 'AUTHENTIC FEET 09/10'
    expect(subject[3].transaction_date).to eq Date.parse('2022-01-11')
    expect(subject[3].first_installment_date).to eq Date.parse('2021-05-11')
    expect(subject[3].account_name).to eq 'PERSON 2'
    expect(subject[3].card_number).to eq '6230'
    expect(subject[3].id).to eq '623020220111-92990910AUTHENTICFEET0910'

    expect(subject[14].amount).to eq '-205.59'
    expect(subject[14].payee).to eq 'PARC=108AIRBNB PAGA'
    expect(subject[14].memo).to eq 'PARC=108AIRBNB PAGA 04/08'
    expect(subject[14].transaction_date).to eq Date.parse('2022-01-12')
    expect(subject[14].first_installment_date).to eq Date.parse('2021-10-12')
    expect(subject[14].account_name).to eq 'PERSON 1'
    expect(subject[14].card_number).to eq '3311'
  end
end
