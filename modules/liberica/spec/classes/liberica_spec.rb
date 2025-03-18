# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'liberica' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    let(:pre_condition) { 'include prometheus::node_exporter' }
    context "On #{os}" do
      let(:facts) { facts }
      context "On ensure present" do
        let(:params) {
          {
            config: {
              hcforwarder: {
                log_level: 'info',
                grpc: {
                  network: 'tcp',
                  address: '127.0.0.1:3000',
                },
                prometheus: {
                  addresses: [':2020'],
                },
                hashing_algorithm: 'jenkins',
                interface: {
                  egress: 'eth0',
                  v4: 'ipip0',
                  v6: 'ipip60',
                },
              },
              healthcheck: {
                log_level: 'debug',
                grpc: {
                  network: 'unix',
                  address: '/var/run/healthcheck.socket',
                },
                prometheus: {
                  addresses: [':2021'],
                },
              },
              fp: {
                log_level: 'info',
                grpc: {
                  network: 'tcp',
                  address: '127.0.0.1:3001',
                },
                prometheus: {
                  addresses: [':2022'],
                },
                forwarding_plane: 'ipvs',
              },
              cp: {
                log_level: 'info',
                grpc: {
                  network: 'tcp',
                  address: '127.0.0.1:3003',
                },
                prometheus: {
                  addresses: [':2023'],
                },
              },
              etcd: {
                conftool_domain: 'eqiad.wmnet',
                datacenter: 'drmrs',
              },
              bgp: {
                grpc: {
                  network: 'tcp',
                  address: '127.0.0.1:3002',
                },
                asn: 64_512,
                peers: ['127.0.0.2'],
                next_hop_ipv4: '127.0.0.1',
                next_hop_ipv6: '::1',
                communities: ['14907:0'],
              },
              services: {
                foobar: {
                  forward_type: 'tunnel',
                  depool_threshold: 0.5,
                  cluster: 'foo',
                  service: 'bar',
                  ip: '192.2.0.1',
                  port: 80,
                  protocol: 'tcp',
                  healthchecks: {
                    'L4': {
                      type: 'IdleTCPConnectionCheck',
                      timeout: '1s',
                      check_period: '300ms',
                      reconnect_period: '1s',
                    },
                  },
                },
              },
            },
            gobgp_metrics_address: '127.0.0.1:3010',
          }
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('liberica') }
        it { is_expected.to contain_user('liberica') }
        it { is_expected.to contain_file('/etc/liberica').with_ensure('directory')}
        it { is_expected.to contain_file('/etc/liberica/config.yaml').with_owner('root').with_content(<<-EOM
---
hcforwarder:
  log_level: info
  grpc:
    network: tcp
    address: 127.0.0.1:3000
  prometheus:
    addresses:
    - ":2020"
  hashing_algorithm: jenkins
  interface:
    egress: eth0
    v4: ipip0
    v6: ipip60
healthcheck:
  log_level: debug
  grpc:
    network: unix
    address: "/var/run/healthcheck.socket"
  prometheus:
    addresses:
    - ":2021"
fp:
  log_level: info
  grpc:
    network: tcp
    address: 127.0.0.1:3001
  prometheus:
    addresses:
    - ":2022"
  forwarding_plane: ipvs
cp:
  log_level: info
  grpc:
    network: tcp
    address: 127.0.0.1:3003
  prometheus:
    addresses:
    - ":2023"
etcd:
  conftool_domain: eqiad.wmnet
  datacenter: drmrs
bgp:
  grpc:
    network: tcp
    address: 127.0.0.1:3002
  asn: 64512
  peers:
  - 127.0.0.2
  next_hop_ipv4: 127.0.0.1
  next_hop_ipv6: "::1"
  communities:
  - '14907:0'
services:
  foobar:
    forward_type: tunnel
    depool_threshold: 0.5
    cluster: foo
    service: bar
    ip: 192.2.0.1
    port: 80
    protocol: tcp
    healthchecks:
      L4:
        type: IdleTCPConnectionCheck
        timeout: 1s
        check_period: 300ms
        reconnect_period: 1s
EOM
        ) }
      end
    end
  end
end
