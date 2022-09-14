# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'gerrit' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          :host          => 'gerrit.example.org',
          :ipv4          => '192.0.2.42',
          :ipv6          => '2001:db8::1',
          :java_home     => '/path/to/java_home',
          :ldap_config   => {
            :'ro-server' => 'ldapro.example.org',
            :'base-dn'   => 'dc=example,dc=org',
          },
          :scap_user     => 'gerrit-deployer',
          :scap_key_name => 'gerrit-ssh-key',
        }
      }
      let(:pre_condition) do
        '''
        User{"gerrit-deployer":}
        Group{"gerrit-deployer":}
        '''
      end
      it { should compile.with_all_deps }
    end
  end
end
