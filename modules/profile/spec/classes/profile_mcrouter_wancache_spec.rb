require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::mcrouter_wancache' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # disable has_ssl so we dont need to worry about mocking secrets
      let(:params){{has_ssl: false}}

      context "with default params" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('mcrouter') }
        it { is_expected.to contain_class('mcrouter') }
        it { is_expected.not_to contain_class('memcached') }
      end
      context "with onhost memcached" do
        let(:params) { super().merge({use_onhost_memcached: true }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('memcached') }
        it { is_expected.to contain_class('memcached') }
      end
      context "with onhost memcached socket" do
        let(:params) { super().merge({use_onhost_memcached: true, use_onhost_memcached_socket: true }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/tmpfiles.d/memcached.conf').with_ensure('present')
                            .with_content(%r%^d /run/memcached 0755 nobody nogroup - -$%)
        }
        it { is_expected.to contain_file('/etc/mcrouter/config.json').with_ensure('present')
        .with_content(%r%unix:\/var\/run\/memcached\/memcached.sock:ascii:plain%)
        }
      end
    end
  end
end
