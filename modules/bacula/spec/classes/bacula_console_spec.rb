require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::console', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) { { :director => 'testdirector' } }

      it { should contain_package('bacula-console') }
    end
  end
end
