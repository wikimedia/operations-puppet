# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'nftables::set' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'testing_define' }
      let(:params) {{ hosts: ['192.0.2.1', '2001:db8::1', 'not.an.ip.org'] }}
      let(:pre_condition) do
        "include nftables
        function dnsquery::lookup($host, $force_ipv6) {
          ['192.0.2.42', '2001:db8::42']
        }
        "
      end
      describe 'default run failes' do
        it { is_expected.to compile.with_all_deps }
        it do
          # rubocop:disable RegexpLiteral
          is_expected.to contain_file('/etc/nftables/sets/testing_define_ipv4.nft')
            .with_content(/
                          set\stesting_define_v4\s{\s+
                          type\sipv4_addr\s+
                          elements\s=\s{\s+
                              192\.0\.2\.1,\s+
                              192\.0\.2\.42\s+
                            }\s+
                          }
                          /x)
        end
        it do
          is_expected.to contain_file('/etc/nftables/sets/testing_define_ipv6.nft')
            .with_content(/
                          set\stesting_define_v6\s{\s+
                          type\sipv6_addr\s+
                          elements\s=\s{\s+
                              2001:db8::1,\s+
                              2001:db8::42\s+
                            }\s+
                          }
                          /x)
        end
        context 'with prefix' do
          let(:params) {{ hosts: ['192.0.2.1/24', '2001:db8::1/64'] }}
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_file('/etc/nftables/sets/testing_define_ipv4.nft')
              .with_content(/
                            set\stesting_define_v4\s{\s+
                            type\sipv4_addr\s+
                            flags\sinterval\s+
                            elements\s=\s{\s+
                                192\.0\.2\.1\/24\s+
                              }\s+
                            }
                            /x)
          end
          it do
            is_expected.to contain_file('/etc/nftables/sets/testing_define_ipv6.nft')
              .with_content(/
                            set\stesting_define_v6\s{\s+
                            type\sipv6_addr\s+
                            flags\sinterval\s+
                            elements\s=\s{\s+
                                2001:db8::1\/64\s+
                              }\s+
                            }
                            /x)
            # rubocop:enable RegexpLiteral
          end
        end
      end
    end
  end
end
