# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloud_private_subnet' do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) do
        "function dnsquery::a($fqdn) {
            if $fqdn == 'cloudlb2001-dev.codfw.hw.wikimedia.cloud' {
                ['172.20.5.2', '127.0.0.1']
            } elsif $fqdn == 'cloudsw.codfw.hw.wikimedia.cloud' {
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
        'vlan_id'     => 2151,
        'supernet'    => '172.20.0.0/16',
        'public_vips' => '185.15.57.24/29',
      }}
      it { is_expected.to compile.with_all_deps }
      it { should_not contain_class("profile::bird::anycast") }
      it { should_not contain_file("/etc/iproute2/rt_tables.d/cloud-private.conf") }
      it { should_not contain_interface__post_up_command("cloud-private_default_gw") }
      it { should_not contain_interface__post_up_command("cloud-private_route_lookup_rule") }
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
        is_expected.to contain_interface__route("cloud_private_subnet_route")
              .with_address("172.20.0.0")
              .with_prefixlen("16")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
      }
      it {
        is_expected.to contain_interface__route("cloud_private_subnet_public_vips_route")
              .with_address("185.15.57.24")
              .with_prefixlen("29")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
      }
      context "when enabling BGP" do
        let(:params) {
            super().merge({
                'do_bgp' => true,
            })
        }
        it { is_expected.to compile.with_all_deps }
        it {
            is_expected.to contain_class("profile::bird::anycast")
                .with_ipv4_src("172.20.5.2")
                .with_neighbors_list(["172.20.5.1"])
        }
        it {
          is_expected.to contain_file("/etc/iproute2/rt_tables.d/cloud-private.conf")
                .with_ensure("present")
                .with_content("100 cloud-private\n")
        }
        it {
          is_expected.to contain_interface__post_up_command("cloud-private_default_gw")
                .with_interface("vlan2151")
                .with_command("ip route add default via 172.20.5.1 table cloud-private")
        }
        it {
          is_expected.to contain_interface__post_up_command("cloud-private_route_lookup_rule")
                .with_interface("vlan2151")
                .with_command("ip rule add from 185.15.57.24/29 table cloud-private")
        }
      end
    end
  end
end
