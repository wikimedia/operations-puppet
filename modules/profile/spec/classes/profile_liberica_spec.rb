# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::liberica' do
  let(:pre_condition) do
    [
      'class { "::prometheus::node_exporter": }',
    ]
  end
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
        let(:facts) do
          os_facts.merge({
            'networking' => {
              'hostname' => 'lvs7003',
            },
            'site' => 'magru',
            'interface_primary' => 'enp4s0f0',
            'default_routes' => {
              'ipv4' => '10.0.0.1',
            },
            'net_driver' => {
              'enp4s0f0' => {
                'driver'            => 'bnx2x',
                'duplex'            => 'full',
                'speed'             => 10_000,
                'firwmware_version' => 'FFV14.10.07 bc 7.14.11',
              },
            },
          })
        end
        let(:params) {
          {
            hcforwarder_config: {
              log_level: 'info',
              grpc: {
                network: 'tcp',
                address: '127.0.0.1:1100'
              },
              prometheus: {
                addresses: ['127.0.0.1:3000'],
              },
              hashing_algorithm: 'jenkins',
              interface: {
                egress: 'enp4s0f0',
                v4: 'ipip0',
                v6: 'ipip60'
              }
            },
            healthcheck_config: {
              log_level: 'info',
              grpc: {
                network: 'tcp',
                address: '127.0.0.1:1101'
              },
              prometheus: {
                addresses: ['127.0.0.1:3001'],
              }
            },
            fp_config: {
              log_level: 'info',
              grpc: {
                network: 'tcp',
                address: '127.0.0.1:1102'
              },
              prometheus: {
                addresses: ['127.0.0.1:3002'],
              },
              forwarding_plane: 'katran',
              katran: {
                interface: 'enp4s0f0',
                conntrack_size: 8_000_000,
              }
            },
            cp_config: {
              log_level: 'info',
              grpc: {
                network: 'tcp',
                address: '127.0.0.1:1103'
              },
              prometheus: {
                addresses: ['127.0.0.1:3003'],
              }
            },
            etcd_config: {
              conftool_domain: 'eqiad.wmnet',
              datacenter: 'magru'
            },
            bgp_config: {
              grpc: {
                network: 'tcp',
                address: '127.0.0.1:1104'
              },
              asn: 64_600,
              next_hop_ipv4: '127.0.0.1',
              next_hop_ipv6: '::1',
              peers: ['10.0.0.1']
            },
            include_services: ['ncredir'],
            interface_tweaks: {enp4s0f0: {}},
            gobgp_metrics_address: '127.0.0.1:3010'
          }
        }
        it { is_expected.to compile.with_all_deps }
    end
  end
end
