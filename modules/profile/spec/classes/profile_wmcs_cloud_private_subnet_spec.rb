# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloud_private_subnet' do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge({
        'interface_primary' => 'eno1',
      }) }
      let(:params) {{
        'vlan_id' => 2151,
        'address' => '172.20.5.2/24',
      }}
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_interface__tagged("cloud_private_subnet_iface")
              .with_base_interface("eno1")
              .with_vlan_id("2151")
              .with_method("manual")
              .with_legacy_vlan_naming(false)
      }
      it {
        is_expected.to contain_interface__ip("cloud_private_subnet_ip")
              .with_interface("vlan2151")
              .with_address("172.20.5.2")
              .with_prefixlen("24")
      }
    end
  end
end
