require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::geoip' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) {
        '''
        include profile::puppet::agent
        include httpd
        include puppetmaster
        include prometheus::node_exporter
        '''
      }
      it { is_expected.to compile }
    end
  end
end
