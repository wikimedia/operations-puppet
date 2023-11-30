require_relative '../../../../rake_modules/spec_helper'

describe 'profile::tlsproxy::envoy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          services: [{server_names: ['*'], port: 80, cert_name: 'test'}],
          global_cert_name: 'example',
          tls_port: 4443
        }
      }

      context "global TLS, non-SNI" do
        let(:params) { super().merge(tls_port: 443) }

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_class('envoyproxy')
                           .with_ensure('present')
        }
        it {
          is_expected.to contain_envoyproxy__tls_terminator('443')
                           .with_global_certs([{'cert_path' => '/etc/ssl/localcerts/example.crt', 'key_path' => '/etc/ssl/private/example.key'}])
                           .with_retry_policy({})
        }
        it {
          is_expected.to contain_sslcert__certificate('example')
                           .with_ensure('present')
        }
      end

      context 'test upstream_addr' do
        context "default" do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_envoyproxy__tls_terminator('4443').with_upstreams([
              'server_names'  => ['*'],
              'certificates'  => nil,
              'upstream'      => {'port' => 80, 'addr' => facts[:fqdn]}
            ])
          end
        end
        [
          'localhost', '127.0.0.1', '::1',
          facts[:networking]['ip'], facts[:networking]['ip6']
        ].reject{|e| e.to_s.empty? }.each do |valid|
          context "valid: #{valid}" do
            let(:params) { super().merge(upstream_addr: valid) }

            it { is_expected.to compile.with_all_deps }
            it do
              is_expected.to contain_envoyproxy__tls_terminator('4443').with_upstreams([
                'server_names'  => ['*'],
                'certificates'  => nil,
                'upstream'      => {'port' => 80, 'addr' => valid}
              ])
            end
          end
        end
        ['foobar', '192.0.2.1', '2001:db8::1'].each do |invalid|
          context "invalid #{invalid}" do
            let(:params) { super().merge(upstream_addr: 'foobar') }

            it do
              is_expected.to raise_error(
                Puppet::PreformattedError, /upstream_addr must be one of:/
              )
            end
          end
        end
      end
      context "SNI-only" do
        let(:params) do
          super().merge(
            sni_support: 'strict',
            services: [
              {server_names: ['citoid.discovery.wmnet', 'citoid'], port: 8080, cert_name: 'citoid'},
            ]
          )
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_envoyproxy__tls_terminator('4443')
                          .with_retry_policy({})
                          .with_upstream_response_timeout(65.0)
        }
        context "No retries" do
          let(:params) { super().merge(retries: false) }

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_envoyproxy__tls_terminator('4443')
                              .with_retry_policy({"num_retries" => 0})
          }
        end
        context "Larger timeout" do
          let(:params) { super().merge(upstream_response_timeout: 201.0) }

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_envoyproxy__tls_terminator('4443')
                              .with_upstream_response_timeout(201.0)
          }
        end
      end
    end
  end
end
