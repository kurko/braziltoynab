RSpec.shared_examples "transaction" do
  it { respond_to(:id) }
  it { respond_to(:transaction_date) }
  it { respond_to(:first_installment_date) }
  it { respond_to(:amount) }
  it { respond_to(:payee) }
  it { respond_to(:memo) }
  it { respond_to(:installments_string) }
  it { respond_to(:total_installments) }
  it { respond_to(:current_installment) }
  it { respond_to(:future_installments?) }
end
