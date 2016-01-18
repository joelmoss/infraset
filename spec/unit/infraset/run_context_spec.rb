RSpec.describe Infraset::RunContext, :focus do
  before(:each) { @run_context = described_class.new }

  it 'initializes with @resources attribute accessor' do
    expect(@run_context.resources).to be_an(Infraset::Resources)
  end

  describe '#read_state' do

  end

end