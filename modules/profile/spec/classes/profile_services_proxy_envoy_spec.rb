require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9', '10'],
    }
  ]
}

describe 'profile::services_proxy::envoy' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge({ initsystem: 'systemd' }) }
      let(:pre_condition) {
        [
          'class profile::base { $notifications_enabled = false }',
          'require ::profile::base'
        ]
      }

      let(:node_params) {
        {test_name: 'proxy_envoy', site: 'unicornia'}
      }
      context 'with ensure present' do
        let(:params) {
          {
            ensure: 'present',
            listeners: [
              {
                name: 'commons',
                port: 8765,
                timeout: '2s',
                retry: {
                  retry_on: "5xx",
                  num_retries: 1
                },
                keepalive: '5s',
                http_host: 'commons.wikimedia.org',
                service: 'appservers-https',
                dnsdisc: 'appservers-rw'
              },
              {
                name: 'meta',
                port: 9876,
                timeout: '2s',
                http_host: 'meta.wikimedia.org',
                service: 'text-https',
                site: 'eqiad'
              },
            ],
          }
        }
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_envoyproxy__cluster('text-https_eqiad_cluster')
                           .with_content(/address: text-lb.eqiad.wikimedia.org/)
                           .with_content(/name: text-https_eqiad/)
                           .without_content(/common_http_protocol_options/)
        }
        it {
          is_expected.to contain_envoyproxy__cluster('appservers-rw_cluster')
                           .with_content(/address: appservers-rw.discovery.wmnet/)
                           .with_content(/name: appservers-rw/)
                           .with_content(/idle_timeout: 5s/)
        }
        it {
          is_expected.to contain_envoyproxy__listener('commons')
                           .with_content(/host_rewrite: commons.wikimedia.org/)
                           .with_content(/retry_on: "5xx"/)
                           .with_content(/num_retries: 1/)
                           .with_content(/cluster: appservers-rw/)
        }
        it {
          is_expected.to contain_envoyproxy__listener('meta')
                           .with_content(/timeout: 2s/)
                           .with_content(/num_retries: 0/)
                           .with_content(/cluster: text-https_eqiad/)
                           .with_content(/port_value: 9876/)
        }
      end
    end
  end
end
