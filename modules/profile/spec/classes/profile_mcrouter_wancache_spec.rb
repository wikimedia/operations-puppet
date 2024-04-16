require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::mcrouter_wancache' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context "with default params" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('mcrouter') }
        it { is_expected.to contain_class('mcrouter') }
        it { is_expected.not_to contain_class('memcached') }
      end
    end
  end
end
