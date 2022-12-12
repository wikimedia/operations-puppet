# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'cloudlb::haproxy::service' do
  let(:title) { 'service1' }
  let(:pre_condition) {
    """
    include haproxy
    include network::constants
    """
  }

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| "127.0.0.10" }
      end
      let(:node_params) {{'_role' => 'wmcs::cloudlb'}}
      let(:facts) { os_facts.merge({
        'fqdn' => 'cloudlb1001',
      }) }
      context "when open firewall and 2 frontends" do
          let(:params) {{
            'service' => {
                'type' => 'http',
                'open_firewall' => true,
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
            is_expected.to contain_ferm__service('service1_11111').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => '11111'
                ).without_srange
            is_expected.to contain_ferm__service('service1_11112').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => '11112'
                ).without_srange
          }
      end
      context "when closed firewall and 2 frontends" do
          let(:params) {{
            'service' => {
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
          }}
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/etc/haproxy/conf.d/service1.cfg')
            is_expected.to contain_ferm__service('service1_11111').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => '11111'
                )
            is_expected.to contain_ferm__service('service1_11112').with(
                    'ensure' => 'present',
                    'proto'  => 'tcp',
                    'port'   => '11112'
                )
          }
      end
    end
  end
end
