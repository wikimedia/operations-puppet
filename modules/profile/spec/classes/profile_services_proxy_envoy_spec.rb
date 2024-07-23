require_relative '../../../../rake_modules/spec_helper'

describe 'profile::services_proxy::envoy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    let(:facts) { facts }

    context "on #{os}" do
      context 'with ensure present' do
        let(:params) {
          {
            ensure: 'present',
            all_listeners: [
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
                service: 'mw-api-int',
                upstream: 'mw-api-int.discovery.wmnet',
                xfp: 'https'
              },
              {
                name: 'meta',
                port: 9876,
                timeout: '2s',
                http_host: 'meta.wikimedia.org',
                service: 'text-https',
                upstream: 'text-lb.eqiad.wikimedia.org'
              },
            ],
            enabled_listeners: ['commons', 'meta']
          }
        }
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_envoyproxy__cluster('text-https_eqiad_cluster')
                           .with_content(/address: text-lb.eqiad.wikimedia.org/)
                           .with_content(/name: text-https_eqiad/)
                           .with_content(/envoy\.extensions\.transport_sockets\.tls\.v3/)
                           .without_content(/common_http_protocol_options/)
        }
        it {
          is_expected.to contain_envoyproxy__cluster('mw-api-int_cluster')
                           .with_content(/address: mw-api-int.discovery.wmnet/)
                           .with_content(/name: mw-api-int/)
                           .with_content(/idle_timeout: 5s/)
        }
        it {
          is_expected.to contain_envoyproxy__listener('commons')
                           .with_content(/host_rewrite_literal: commons.wikimedia.org/)
                           .with_content(/value: "https"/)
                           .with_content(/retry_on: "5xx"/)
                           .with_content(/num_retries: 1/)
                           .with_content(/cluster: mw-api-int/)
        }
        it {
          is_expected.to contain_envoyproxy__listener('meta')
                           .with_content(/timeout: 2s/)
                           .without_content(/request_headers_to_add:/)
                           .with_content(/num_retries: 0/)
                           .with_content(/cluster: text-https_eqiad/)
                           .with_content(/port_value: 9876/)
                           .with_content(/envoy\.extensions\.access_loggers/)
        }
      end
    end
  end
end
