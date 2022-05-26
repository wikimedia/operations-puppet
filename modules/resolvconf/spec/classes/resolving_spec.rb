# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'resolvconf' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          'networking' => os_facts[:networking].merge({'domain' => 'example.com'}),
        })
      end
      let(:params){ {'nameservers' => ['192.0.2.53']}}

      context "default" do
        it { is_expected.to compile.with_all_deps }
        it "contains a correct resolv.conf"  do
          is_expected.to contain_file('/etc/resolv.conf')
            .with_owner('root')
            .with_group('root')
            .with_mode('0444')
            .with_content(/search example.com/)
            .with_content(/options timeout:1 attempts:3 ndots:1/)
            .with_content(/nameserver 192.0.2.53/)
        end
        it { is_expected.not_to contain_file('/sbin/resolvconf') }
        it { is_expected.not_to contain_file('/etc/dhcp/dhclient-enter-hooks.d') }
        it { is_expected.not_to contain_file('/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate') }
      end

      context "with disable_resolvconf" do
        let(:params) { super().merge(disable_resolvconf: true) }

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/sbin/resolvconf')
            .with_source('puppet:///modules/resolvconf/resolvconf.dummy')
        end
      end
      context "with disable_dhcpupdates" do
        let(:params) { super().merge(disable_dhcpupdates: true) }

        it do
          is_expected.to contain_file('/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate')
            .with_source('puppet:///modules/resolvconf/nodnsupdate')
        end
      end
    end
  end
end
