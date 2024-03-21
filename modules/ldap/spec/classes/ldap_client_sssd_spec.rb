require_relative '../../../../rake_modules/spec_helper'
require 'rspec-puppet/cache'

describe 'ldap::client::sssd' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          'servers'      => ['server1', 'server2'],
          'base_dn'      => 'basedn_value',
          'sudo_base_dn' => 'sudobasedn_value',
          'proxy_pass'   => 'proxypass_value',
          'page_size'    => 2000,
          'ca_file'      => 'ca-certificates.crt',
        }
      }
      it { should compile }
    end
  end
end
