# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'bird' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { neighbors: ['192.0.2.1', '2001:db8::1'] } }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/bird/bird.conf')
            .with_ensure('present')
            .with_content(%r{include\s+"/etc/bird/anycast-prefixes.conf"})
            .with_content(/192.0.2.1/)
            .without_content(/2001:db8::1/)
            .without_content(%r{include\s+"/etc/bird/anycast6-prefixes.conf"})
        end
      end
      describe 'test with ipv6' do
        let(:params) { super().merge(do_ipv6: true) }

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/bird/bird.conf')
            .with_ensure('present')
            .with_content(%r{include\s+"/etc/bird/anycast6-prefixes.conf"})
            .with_content(/2001:db8::1/)
            .with_content(/192.0.2.1/)  # The current setup assumes that IPv6 is enabled in addition to IPv4.
        end
      end
      describe 'test with bind_service' do
        let(:params) { super().merge(bind_service: 'foobar') }
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
