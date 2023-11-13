# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'cloudlb::haproxy::service' do
  let(:title) { 'service1' }
  let(:pre_condition) {
    """
    include haproxy
    """
  }

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:node_params) {{'_role' => 'wmcs::cloudlb'}}
      let(:facts) { os_facts.merge({
        'fqdn' => 'cloudlb1001',
      }) }
      context "when open firewall and 2 frontends" do
          let(:params) {{
            'service' => {
                'type' => 'http',
                'firewall' => {
                    'open_to_internet' => true,
                },
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
          }}
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/etc/haproxy/conf.d/service1.cfg')
            is_expected.to contain_firewall__service('service1_11111').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => 11_111
                ).without_srange.without_src_sets
            is_expected.to contain_firewall__service('service1_11112').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => 11_112
                ).without_srange.without_src_sets
          }
      end
      context "when closed firewall and 2 frontends" do
          let(:params) {{
            'service' => {
                'type' => 'http',
                'firewall' => {
                    'open_to_internet' => false,
                },
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
          }}
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/etc/haproxy/conf.d/service1.cfg')
            is_expected.to contain_firewall__service('service1_11111').with(
                    'ensure'   => 'present',
                    'proto'    => 'tcp',
                    'port'     => 11_111,
                    'src_sets' => ['PRODUCTION_NETWORKS', 'LABS_NETWORKS']
                ).without_srange
            is_expected.to contain_firewall__service('service1_11112').with(
                    'ensure'   => 'present',
                    'proto'    => 'tcp',
                    'port'     => 11_112,
                    'src_sets' => ['PRODUCTION_NETWORKS', 'LABS_NETWORKS']
                ).without_srange
          }
      end
      context "when FQDN-based-firewall and 2 frontends" do
          let(:params) {{
            'service' => {
                'type' => 'http',
                'firewall' => {
                    'restricted_to_fqdns' => [
                        'sourcehost1.example.com',
                        'sourcehost2.example.com',
                    ],
                },
                'frontends' => [
                    {
                        'port' => 11_114,
                        'acme_chief_cert_name' => 'example.com',
                    },
                    {
                        'port' => 11_115,
                        'acme_chief_cert_name' => 'example.com',
                     },
                 ],
                 'backend' => {
                     'port' => 22_223,
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
          }}
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/etc/haproxy/conf.d/service1.cfg')
            is_expected.to contain_firewall__service('service1_11114').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => 11_114,
                    'srange' => [
                        'sourcehost1.example.com',
                        'sourcehost2.example.com',
                    ]
                ).without_src_sets
            is_expected.to contain_firewall__service('service1_11115').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => 11_115,
                    'srange' => [
                        'sourcehost1.example.com',
                        'sourcehost2.example.com',
                    ]
                ).without_src_sets
          }
      end
    end
  end
end
