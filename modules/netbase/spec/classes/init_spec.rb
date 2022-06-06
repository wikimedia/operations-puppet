# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbase' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          services: {
            'simple_tcp' => {'port' => 10_001, 'protocols' => ['tcp']},
            'simple_udp' => {'port' => 10_002, 'protocols' => ['udp']},
            'multi' => {'port' => 10_003, 'protocols' => ['tcp', 'udp']},
            'tcp_aliases' => {
              'port' => 10_004,
              'protocols' => ['tcp'],
              'aliases' => ['foo', 'bar']
            },
            'udp_description' => {
              'port' => 10_005,
              'protocols' => ['udp'],
              'description' => 'foobar'
            },
            'multi_description_aliases' => {
              'port' => 10_006,
              'protocols' => ['udp', 'tcp'],
              'aliases' => ['foo', 'bar'],
              'description' => 'foobar'
            },
          }
        }
      end
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/services')
            .with_content(/#### Managed by puppet ####/)
            .with_content(%r{^tcpmux\s1/tcp\s#\sTCP port service multiplexer$})
            .with_content(%r{^echo\s7/tcp$})
            .with_content(%r{^echo\s7/udp$})
            .with_content(%r{^kerberos\s88/tcp\skerberos5\skrb5\skerberos-sec\s#\sKerberos\sv5$})
            .with_content(%r{^simple_tcp\s10001/tcp$})
            .with_content(%r{^simple_udp\s10002/udp$})
            .with_content(%r{^multi\s10003/tcp$})
            .with_content(%r{^multi\s10003/udp$})
            .with_content(%r{^tcp_aliases\s10004/tcp\sfoo\sbar$})
            .with_content(%r{^udp_description\s10005/udp\s#\sfoobar$})
            .with_content(%r{^multi_description_aliases\s10006/udp\sfoo\sbar\s#\sfoobar$})
            .with_content(%r{^multi_description_aliases\s10006/tcp\sfoo\sbar\s#\sfoobar$})
        end
      end
      describe 'test without managing etc_services' do
        let(:params) { super().merge(manage_etc_services: false) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('/etc/services') }
      end
    end
  end
end
