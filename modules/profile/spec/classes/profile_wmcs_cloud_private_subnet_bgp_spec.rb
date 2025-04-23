# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloud_private_subnet::bgp' do
  on_supported_os(WMFConfig.test_on(11, 12)).each do |os, facts|
    context "on #{os}" do
      let(:node_params) { { 'site' => 'codfw' } }
      let(:facts) { facts.merge({
        'hostname' => 'cloudlb2002-dev',
      }) }
      let(:params) {{
        'vips' => {
          'openstack.codfw1dev.wikimediacloud.org' => {
            'ensure' => 'present',
            'check_cmd' => 'whatever',
            'service_type' => 'whatever',
            'address' => '185.15.57.24',
          },
          'other' => {
            'ensure' => 'present',
            'check_cmd' => 'whatever',
            'check_cmd_ipv6' => 'whatever',
            'service_type' => 'whatever',
            'address' => '192.0.2.1',
            'address_ipv6' => '3fff::ffff',
          },
        },
      }}
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
          } elsif $name == 'cloudlb2002-dev.private.codfw.wikimedia.cloud' {
            ['172.20.5.3']
          } elsif $name == 'cloudsw-b1.private.codfw.wikimedia.cloud' {
            ['172.20.5.1', '127.0.0.2']
          }
        }

        function dnsquery::aaaa ($name) {
          if $name == 'cloudlb2004-dev.private.codfw.wikimedia.cloud' {
            []
          } elsif $name == 'cloudlb2002-dev.private.codfw.wikimedia.cloud' {
            ['3fff::2001']
          } elsif $name == 'cloudsw-b1.private.codfw.wikimedia.cloud' {
            ['3fff::1']
          }
        }

        class { 'profile::wmcs::cloud_private_subnet':
          cloud_private_gw_t => 'cloudsw-<%= $rack %>.private.codfw.wikimedia.cloud',
          vlan_mapping       => {
            'codfw' => {
              'b1' => 2151,
            },
          },
          netbox_location    => {
            rack => 'B1',
            row  => 'codfw-row-b',
            site => 'codfw',
          },
        }"
      end

      it { is_expected.to compile.with_all_deps }

      it {
          is_expected.to contain_class("profile::bird::anycast")
              .with_ipv4_src("172.20.5.3")
      }

      it "should have a routing table" do
        is_expected.to contain_interface__routing_table("cloud-private")
              .with_number(100)
      end

      it "should have default IPv4 route in the routing table" do
        is_expected.to contain_interface__route("cloud-private_default_gw4")
              .with_interface("vlan2151")
              .with_address("default")
              .with_table("cloud-private")
              .with_nexthop("172.20.5.1")
              .with_persist(true)
      end

      it "should have rules to use routing table for IPv4 VIPs" do
        is_expected.to contain_interface__post_up_command("cloud-private_route_lookup_rule_openstack.codfw1dev.wikimediacloud.org_v4")
              .with_interface("vlan2151")
              .with_command("ip rule add from 185.15.57.24/32 table cloud-private")
        is_expected.to contain_interface__post_up_command("cloud-private_route_lookup_rule_other_v4")
              .with_interface("vlan2151")
              .with_command("ip rule add from 192.0.2.1/32 table cloud-private")
      end

      context "with IPv6 support" do
        it {
          is_expected.to contain_class("profile::bird::anycast")
              .with_neighbors_list(["172.20.5.1", "3fff::1"])
        }

        it "should have default IPv6 route in the routing table" do
          is_expected.to contain_interface__route("cloud-private_default_gw6")
                .with_interface("vlan2151")
                .with_address("default")
                .with_table("cloud-private")
                .with_nexthop("3fff::1")
                .with_persist(true)
        end

        it "should have rules to use routing table for IPv6 VIPs" do
          is_expected.to contain_interface__post_up_command("cloud-private_route_lookup_rule_other_v6")
                .with_interface("vlan2151")
                .with_command("ip -6 rule add from 3fff::ffff/128 table cloud-private")
        end

        it "should not have rules to use routing table for IPv6 VIPs for v4-only services" do
          is_expected.not_to contain_interface__post_up_command("cloud-private_route_lookup_rule_openstack.codfw1dev.wikimediacloud.org_v6")
        end
      end

      context "without IPv6 support" do
        let(:facts) { facts.merge({
          'hostname' => 'cloudlb2004-dev',
        }) }

        it {
          is_expected.to contain_class("profile::bird::anycast")
              .with_neighbors_list(["172.20.5.1"])
        }

        it "should not have default IPv6 route in the routing table" do
          is_expected.not_to contain_interface__route("cloud-private_default_gw6")
        end

        it "should not have rules to use routing table for IPv6 VIPs" do
          is_expected.not_to contain_interface__post_up_command("cloud-private_route_lookup_rule_other_v6")
        end
      end
    end
  end
end
