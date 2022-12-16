# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::cloudlb::haproxy' do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |os, facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| "127.0.0.10" }
      end
      let(:facts) { facts.merge({
        'fqdn' => 'cloudlb1001',
      }) }
      let(:params) {{
        'cloudlb_haproxy_config' => {
            'testservice1' => {
                'type' => 'http',
                'open_firewall' => false,
                'frontends' => [
                    {
                        'port' => 11_111,
                        'acme_chief_cert_name' => 'example.com',
                    },
                    {
                        'port' => 11_112,
                        'acme_chief_cert_name' => 'example.com',
                    },
                ],
                'backend' => {
                    'port' => 22_222,
                    'servers' => [
                        'testbackend1',
                        'testbackend2',
                    ],
                },
                'healthcheck' => {
                    'method' => 'GET',
                    'path' => '/health',
                },
            },
            'testservice2' => {
                'type' => 'tcp',
                'open_firewall' => true,
                'frontends' => [
                    {
                        'port' => 33_333,
                        'acme_chief_cert_name' => 'example.com',
                    },
                ],
                'backend' => {
                    'port' => 44_444,
                    'servers' => [
                        'testbackend3',
                        'testbackend4',
                    ],
                },
                'healthcheck' => {
                    'options' => [
                        'healthcheck_option1',
                        'healthcheck_option2',
                    ]
                },
            },
         },
        'acme_chief_cert_name' => 'example.com',
      }}
      let(:node_params) {{'_role' => 'wmcs::cloudlb'}}
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_acme_chief__cert('example.com')
        is_expected.to contain_class('haproxy')
        is_expected.to contain_file('/etc/haproxy/ipblocklist.txt')
        is_expected.to contain_file('/etc/haproxy/agentblocklist.txt')
        is_expected.to contain_class('cloudlb::haproxy::load_all_config')
        is_expected.to contain_cloudlb__haproxy__service('testservice1')
            .with_service(
                'type' => 'http',
                'open_firewall' => false,
                'frontends' => [
                    {
                        'port' => 11_111,
                        'acme_chief_cert_name' => 'example.com',
                    },
                    {
                        'port' => 11_112,
                        'acme_chief_cert_name' => 'example.com',
                    },
                ],
                'backend' => {
                    'port' => 22_222,
                    'servers' => [
                        'testbackend1',
                        'testbackend2',
                    ],
                },
                'healthcheck' => {
                    'method' => 'GET',
                    'path' => '/health',
                }
            )
        is_expected.to contain_cloudlb__haproxy__service('testservice2')
            .with_service(
                'type' => 'tcp',
                'open_firewall' => true,
                'frontends' => [
                    {
                        'port' => 33_333,
                        'acme_chief_cert_name' => 'example.com',
                    },
                ],
                'backend' => {
                    'port' => 44_444,
                    'servers' => [
                        'testbackend3',
                        'testbackend4',
                    ],
                },
                'healthcheck' => {
                    'options' => [
                        'healthcheck_option1',
                        'healthcheck_option2',
                    ],
                }
            )
      }
    end
  end
end
