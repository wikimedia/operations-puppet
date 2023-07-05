# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloud_private_subnet' do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) do
        "function dnsquery::a($fqdn) {
            if $fqdn == 'cloudlb2001-dev.private.codfw.wikimedia.cloud' {
                ['172.20.5.2', '127.0.0.1']
            } elsif $fqdn == 'cloudsw-b1.private.codfw.wikimedia.cloud' {
                ['172.20.5.1', '127.0.0.2']
            } else {
                [$fqdn]
            }
        }"
      end
      let(:node_params) { { 'site' => 'codfw' } }
      let(:facts) { facts.merge({
        'interface_primary' => 'eno1',
        'hostname' => 'cloudlb2001-dev',
      }) }
      let(:params) {{
        'cloud_private_gw_t' => 'cloudsw-<%= $rack %>.private.codfw.wikimedia.cloud',
        'vlan_mapping' => {
            'codfw' => {
                'b1' => 2151,
            },
            'eqiad' => {
                'a1' => 1151,
                'a2' => 1152,
            },
        },
        'supernet'           => '172.20.0.0/16',
        'public_cidrs'       => [
            '185.15.57.0/26',
            '1.2.3.0/24',
        ],
        'netbox_location'    => {
            'rack'           => 'B1',
            'row'            => 'codfw-row-b',
            'site'           => 'codfw',
        },
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
      it {
        is_expected.to contain_interface__route("cloud_private_subnet_route_supernet")
              .with_address("172.20.0.0")
              .with_prefixlen("16")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
      }
      it {
        is_expected.to contain_interface__route("cloud_private_subnet_route_public_0")
              .with_address("185.15.57.0")
              .with_prefixlen("26")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
        is_expected.to contain_interface__route("cloud_private_subnet_route_public_1")
              .with_address("1.2.3.0")
              .with_prefixlen("24")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
      }
    end
  end
end
