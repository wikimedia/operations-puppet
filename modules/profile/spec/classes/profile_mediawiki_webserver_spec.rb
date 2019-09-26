require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'profile::mediawiki::webserver' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:compile_redirects, :type => :rvalue) { |args|
      "compiling #{args}"
    }
    Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |args|
      "got #{args}"
    }
  end
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:node_params) { { :site => 'testsite', :realm => 'production',
                            :test_name => 'mediawiki_webserver',
                            :initsystem => 'systemd',
                            :cluster => 'appserver',
                            :numa_networking => 'off',
                          } }
      let(:pre_condition) {
        [
          'exec { "apt-get update": command => "/bin/true"}',
          'class mediawiki::users($web="www-data"){ notice($web) }',
          'class profile::base { $notifications_enabled = false }',
          'include mediawiki::users',
          'include ::profile::base'
        ]
      }
      let(:params) {
        {
          :has_lvs => false,
          :has_tls => false,
          :vhost_feature_flags => {},
        }
      }
      context "with default params" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__conf('fcgi_proxies')
                              .with_ensure('present')
        }
        it { is_expected.to contain_class('mediawiki::packages::fonts') }
        it { is_expected.to contain_class('mediawiki::web::prod_sites') }
        it { is_expected.to contain_systemd__unit('apache2.service')
                              .with_override(true)
                              .with_content(/PrivateTmp=false/)
        }
        it { is_expected.to contain_mediawiki__web__vhost('wikipedia.org')
                              .with_feature_flags({})
        }
      end
      context "without hhvm" do
        it { is_expected.to compile.with_all_deps }
      end
      context "with tls" do
        let(:params) {
          super().merge({:has_tls => true})
        }
        let(:node) {
          'test1001.testsite'
        }
        let(:facts) {
          super().merge(
            {
              :numa =>
              {
                :device_to_htset => {:lo => []},
                :device_to_node  => {:lo => ["a", "test"]}
              }
            }
          )
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_tlsproxy__localssl('unified')
                              .with_certs(['test1001.testsite'])
        }
        context "with lvs" do
          let(:params) {
            super().merge({:has_lvs => true})
          }
          let(:pre_condition) {
            super().push('class passwords::etcd($accounts = {}){}')
          }
          # We need a real node here
          let(:node) {
            'mw1261.eqiad.wmnet'
          }
          let(:node_params) {
            super().merge({:site => 'eqiad'})
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_cron('hhvm-conditional-restart') }
          it { is_expected.to contain_class('lvs::realserver')
                                .with_realserver_ips(['1.2.3.4'])
          }
          # no icinga config present => default to fqdn
          it { is_expected.to contain_tlsproxy__localssl('unified')
                                .with_certs(['mw1261.eqiad.wmnet'])
          }
          context "with multiple pools" do
            let(:node_params) {
              super().merge({ :test_name => 'mediawiki_webserver_pools' })
            }
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('lvs::realserver')
                                  .with_realserver_ips(['1.2.3.4', '1.2.3.5'])
            }
            it { is_expected.to contain_tlsproxy__localssl('unified')
                                  .with_certs(
                                    [
                                      'appservers.svc.eqiad.wmnet',
                                      'api.svc.eqiad.wmnet'
                                    ])
            }
          end
        end
      end
    end
  end
end
