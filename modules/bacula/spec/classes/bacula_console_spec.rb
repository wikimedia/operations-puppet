require 'spec_helper'

describe 'bacula::console' do
    let(:params) { { :director => 'testdirector' } }

    it { should contain_package('bacula-console') }
end
