require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9', '10'],
    }
  ]
}

describe 'envoyproxy::tls_terminator' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge({:initsystem => 'systemd'})}
      let(:title) { '443' }
      context 'when envoyproxy is defined' do
        let(:pre_condition) {'class { "envoyproxy": ensure => present, admin_port => 9191 }'}

        context 'simple http termination (no SNI)' do
          let(:params) do
            {
                :upstreams => [
                    {
                        :server_names  => ['*'],
                        :upstream_port => 80,
                        :cert_path => :undef,
                        :key_path => :undef
                    },
                ],
                :global_cert_path     => '/etc/ssl/localcerts/appservers.crt',
                :global_key_path      => '/etc/ssl/localcerts/appservers.key',

            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_envoyproxy__listener('tls_terminator_443')
                                .with_priority(0)
                                .with_content(/port_value: 443/)
                                .with_content(/# Non-SNI support/)
                                .with_content(/domains: \["\*"\]/)
                                .without_content(/name: default/)
          }
        end
        context 'multi-service (SNI) termination' do
          let(:title) { "123" }
          let(:params) do
            {
              :upstreams => [
                {
                  server_names: ['citoid.svc.eqiad.wmnet', 'citoid'],
                  cert_path: '/etc/ssl/localcerts/citoid.crt',
                  key_path: '/etc/ssl/localcerts/citoid.key',
                  upstream_port: 1234
                },
                {
                  server_names: ['pdfrenderer.svc.eqiad.wmnet', 'pdfrenderer'],
                  cert_path: '/etc/ssl/localcerts/evil.crt',
                  key_path: '/etc/ssl/localcerts/evil.key',
                  upstream_port: 666
                }],
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_envoyproxy__listener('tls_terminator_123')
                                .with_priority(0)
                                .with_content(/port_value: 123/)
                                .without_content(/# Non-SNI support/)
                                .with_content(/server_names: \["citoid.svc.eqiad.wmnet", "citoid"\]/)
                                .with_content(/route: { cluster: local_port_1234 }/)
          }
        end
      end
      context 'without envoyproxy defined' do
        it { is_expected.to compile.and_raise_error(/envoyproxy::tls_terminator should only be used once/) }
      end
    end
  end
end
