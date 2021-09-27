require_relative '../../../../rake_modules/spec_helper'
require 'rspec-puppet/cache'

describe 'ldap::client::sssd' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:params) {
          {
              'ldapconfig' => {
                  'servernames'          => ['server1', 'server2'],
                  'basedn'               => 'basedn_value',
                  'sudobasedn'           => 'sudobasedn_value',
                  'proxypass'            => 'proxypass_value',
                  'pagesize'             => '2000',
              },
              'ldapincludes' => {},
          }
      }
      it { should compile }
    end
  end
end
