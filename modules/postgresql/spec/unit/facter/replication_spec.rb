require_relative '../../../../../rake_modules/spec_helper'

tests = {
  '9.6' => {
    'psql_output' => 'psql (PostgreSQL) 9.6.22',
    'full_version' => '9.6.22',
  },
  '11' => {
    'psql_output' => 'psql (PostgreSQL) 11.12 (Debian 11.12-0+deb10u1)',
    'full_version' => '11.12',
  },
}

describe 'postgres_version' do
  before(:each) do
    Facter.clear
  end
  let(:facts) { { kernel: 'Linux' } }

  context 'when psql present, returns psql version' do
    before(:each) do
      expect(Facter::Util::Resolution).to receive(:which).at_least(1).and_return('/path/to/psql')
    end
    tests.each_pair do |test, config|
      context "when #{test}" do
        before(:each) do
          expect(Facter::Util::Resolution).to receive(:exec).at_least(1).and_return(config['psql_output'])
        end
        it { expect(Facter.value(:postgres_version)).to eq(config['full_version']) }
      end
    end
  end
  context 'when psql not present, returns nil' do
    it do
      expect(Facter::Util::Resolution).to receive(:which).at_least(1).with('psql').and_return(false)
      expect(Facter.value(:postgres_version)).to be_nil
    end
  end
end
