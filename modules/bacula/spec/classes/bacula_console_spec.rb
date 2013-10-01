require 'spec_helper'

describe 'bacula::console', :type => :class do
    let(:params) { { :director => 'testdirector' } }

    it { should contain_package('bacula-console') }
end
