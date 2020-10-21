require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::console', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) { { :director => 'testdirector' } }
      let(:pre_condition) do
        "class {'base::puppet': ca_source => 'puppet:///files/puppet/ca.production.pem'}
        class profile::base ( $notifications_enabled = 1 ){}
        include profile::base
        "
      end

      it { should contain_package('bacula-console') }
    end
  end
end
