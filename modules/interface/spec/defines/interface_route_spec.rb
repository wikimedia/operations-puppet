# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'interface::route' do
  let(:title) { 'dummyroute' }
  let(:params) do
    {
      address: '10.10.10.10',
      nexthop: '10.0.0.1',
    }
  end

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "defaults" do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('ip route add 10.10.10.10/32 via 10.0.0.1 dev eth0')
          is_expected.not_to contain_interface__post_up_command('dummyroute_persist')
        end
      end
      context "when persisting" do
        let(:params) { super().merge(interface: 'en1', persist: true) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('ip route add 10.10.10.10/32 via 10.0.0.1 dev en1')
          is_expected.to contain_interface__post_up_command('dummyroute_persist').with(
            'interface' => 'en1',
            'command' => 'ip route add 10.10.10.10/32 via 10.0.0.1 dev en1'
          )
        end
      end
      context "when ipv6" do
        let(:params) {{ address: "2001:db8::2", nexthop: "2001:db8::1" }}
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('ip -6 route add 2001:db8::2/128 via 2001:db8::1 dev eth0')
        end
        it { is_expected.not_to contain_interface__post_up_command('dummyroute_persist') }
      end
      context "when ipv6 and persist" do
        let(:params) {{address: "2001:db8::2", nexthop: "2001:db8::1", persist: true}}
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('ip -6 route add 2001:db8::2/128 via 2001:db8::1 dev eth0')
        end
        it do
          is_expected.to contain_interface__post_up_command('dummyroute_persist').with(
            'interface' => 'eth0',
            'command' => 'ip -6 route add 2001:db8::2/128 via 2001:db8::1 dev eth0'
          )
        end
      end
      context "when missmatch ipv6 address ipv4 gw" do
        let(:params) { super().merge(address: "2001:db8::2") }
        it do
          is_expected.to compile.and_raise_error(
            /\$address \(2001:db8::2\) and \$nexthop \(10\.0\.0\.1\) need to use the same ip family/
          )
        end
      end
      context "when missmatch ipv4 address ipv6 gw" do
        let(:params) { super().merge(nexthop: "2001:db8::1") }
        it do
          is_expected.to compile.and_raise_error(
            /\$address \(10\.10\.10\.10\) and \$nexthop \(2001:db8::1\) need to use the same ip family/
          )
        end
      end
    end
  end
end
