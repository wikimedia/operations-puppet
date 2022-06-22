# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'dnsdist' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { 'resolver' => {'name' => 'resolver', 'ip': '127.0.0.1', 'port': 53},
                       'tls_common' => {'cert_chain_path' => '/etc/foo/chain',
                                        'cert_privkey_path' => '/etc/foo/priv',
                                        'ocsp_response_path' => '/etc/foo/ocsp'},
                       'tls_config_doh' => {'min_tls_version' => 'tls1.3',
                                            'ciphers_tls13' => ['TLS_AES_256_GCM_SHA384'],
                                            'ciphers' => ['ECDHE-ECDSA-AES256-GCM-SHA384']},
                       'tls_config_dot' => {'min_tls_version' => 'tls1.2',
                                            'ciphers_tls13' => ['TLS_AES_256_GCM_SHA384'],
                                            'ciphers' => ['ECDHE-ECDSA-AES256-GCM-SHA384']} } }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_systemd__service('dnsdist') }
        it do
          is_expected.to contain_file('/etc/dnsdist/dnsdist.conf')
            .with_ensure('present')
            .with_content(/^newServer/)
            .with_content(/^addDOHLocal/)
            .with_content(/^addTLSLocal/)
        end
      end
    end
  end
end
