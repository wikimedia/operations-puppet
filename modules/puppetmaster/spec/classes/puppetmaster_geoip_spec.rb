require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::geoip' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) {
        '''
        class profile::base ($notifications_enabled = true){}
        exec{"apt-get update": path => "/usr/bin" }
        include profile::base
        include profile::base::puppet
        include httpd
        include puppetmaster
        include standard::prometheus
        '''
      }
      it { is_expected.to compile }
    end
  end
end
