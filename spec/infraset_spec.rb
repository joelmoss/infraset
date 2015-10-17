require 'spec_helper'

describe 'infraset', type: :aruba do
  before(:each) { run('infraset') }

  it { expect(last_command_started).to be_successfully_executed }
end