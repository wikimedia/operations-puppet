require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::webserver' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:compile_redirects, :type => :rvalue) { |args|
      "compiling #{args}"
    }
  end
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:node_params) {{ '_role' => 'mediawiki/appserver' }}
      let(:pre_condition) {
        [
          'class mediawiki::users($web="www-data"){ notice($web) }',
          'include mediawiki::users',
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
        it { is_expected.to contain_class('mediawiki::web::sites') }
        it { is_expected.to contain_mediawiki__web__vhost('wikipedia.org')
                              .with_feature_flags({})
        }
      end
      context "with tls" do
        let(:facts) { super().merge({'cluster' => 'jobrunner'}) }
        let(:params) { super().merge({:has_tls => true}) }
        # stub out the required class. We test it elsewhere
        it { is_expected.to contain_class('profile::tlsproxy::envoy') }
        context "with lvs" do
          let(:params) { super().merge({:has_lvs => true}) }
          context "with jobrunner server" do
            let(:node_params) {{ '_role' => 'mediawiki/jobrunner' }}

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('lvs::realserver')
              .with_realserver_ips(['10.2.2.26', '10.2.2.5'])
            }
          end
        end
      end
    end
  end
end
