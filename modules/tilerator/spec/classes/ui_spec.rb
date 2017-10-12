require 'spec_helper'

describe 'tilerator::ui' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) {
      'fake_secret'
    }
  end
  context 'with default parameters' do
    it { is_expected.to contain_file('/usr/local/bin/notify-tilerator')
                            .with_mode('0555')
                            .with_content(/-j.deleteEmpty \\/)
    }
  end

  context 'with delete_empty => false' do
    let(:params) { {:delete_empty => false} }
    it { is_expected.to contain_file('/usr/local/bin/notify-tilerator')
                            .with_mode('0555')
                            .without_content(/-j.deleteEmpty/)
    }
  end
end
