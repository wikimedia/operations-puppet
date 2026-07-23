# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloud_private_subnet' do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
    let(:pre_condition) do
      "class network::constants () {
        $cloud_instance_networks = {
          'codfw' => [
            '192.0.2.0/24',
            '3fff:1::/64',
          ],
        }
      }

      function dnsquery::a ($name) {
        if $name == 'cloudlb2004-dev.private.codfw.wikimedia.cloud' {
          ['172.20.5.5', '127.0.0.1']
        } elsif $name == 'cloudsw-b1.private.codfw.wikimedia.cloud' {
          ['172.20.5.1', '127.0.0.2']
        }
      }

      function dnsquery::aaaa ($name) {
        if $name == 'cloudlb2004-dev.private.codfw.wikimedia.cloud' {
          ['3fff::2001']
        } elsif $name == 'cloudsw-b1.private.codfw.wikimedia.cloud' {
          ['3fff::1']
        }
      }"
    end

    context "on #{os}" do
      let(:node_params) { { 'site' => 'codfw' } }
      let(:facts) { facts.merge({
        'interface_primary' => 'eno1',
        'networking' => {
          'hostname' => 'cloudlb2004-dev',
        },
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
        'supernet_v4'        => '172.20.0.0/16',
        'supernet_v6'        => '3fff::/56',
        'public_cidrs'       => [
          '185.15.57.0/26',
          '172.25.0.0/16',
          '3fff:2::/64',
        ],
        'netbox_location' => {
          'rack' => 'B1',
          'row'  => 'codfw-row-b',
          'site' => 'codfw',
        },
      }}
      it { is_expected.to compile.with_all_deps }

      it "should add vlan tag interface" do
        is_expected.to contain_interface__tagged("cloud_private_subnet_iface")
              .with_base_interface("eno1")
              .with_vlan_id(2151)
              .with_method("manual")
      end

      it "should assign addresses to the interface" do
        is_expected.to contain_interface__ip("cloud_private_subnet_ip4")
              .with_interface("vlan2151")
              .with_address("172.20.5.5")
              .with_prefixlen("24")
        is_expected.to contain_interface__ip("cloud_private_subnet_ip6")
              .with_interface("vlan2151")
              .with_address("3fff::2001")
              .with_prefixlen("64")
      end

      it "should add route to cloud-private supernets" do
        is_expected.to contain_interface__route("cloud_private_subnet_route_supernet4")
              .with_address("172.20.0.0/16")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
        is_expected.to contain_interface__route("cloud_private_subnet_route_supernet6")
              .with_address("3fff::/56")
              .with_nexthop("3fff::1")
              .with_interface("vlan2151")
              .with_persist(true)
      end

      it "should add routes to public nets" do
        is_expected.to contain_interface__route("cloud_private_subnet_route_public_185.15.57.0/26")
              .with_address("185.15.57.0/26")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
        is_expected.to contain_interface__route("cloud_private_subnet_route_public_172.25.0.0/16")
              .with_address("172.25.0.0/16")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
        is_expected.to contain_interface__route("cloud_private_subnet_route_public_3fff:2::/64")
              .with_address("3fff:2::/64")
              .with_nexthop("3fff::1")
              .with_interface("vlan2151")
              .with_persist(true)
      end

      it "should add routes to instance nets" do
        is_expected.to contain_interface__route("cloud_private_subnet_route_instances_192.0.2.0/24")
              .with_address("192.0.2.0/24")
              .with_nexthop("172.20.5.1")
              .with_interface("vlan2151")
              .with_persist(true)
        is_expected.to contain_interface__route("cloud_private_subnet_route_instances_3fff:1::/64")
              .with_address("3fff:1::/64")
              .with_nexthop("3fff::1")
              .with_interface("vlan2151")
              .with_persist(true)
      end

      context "for a device without a DNS name" do
        let(:facts) { facts.merge({
          'networking' => {
            'hostname' => 'insetup1001',
          },
        }) }

        it "should not compile" do
          is_expected.not_to compile.with_all_deps
        end
      end
    end
  end
end
