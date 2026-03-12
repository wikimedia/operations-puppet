require_relative '../../../../rake_modules/spec_helper'
describe 'profile::cache::varnish::frontend' do
  on_supported_os(WMFConfig.test_on(11, 13)).each do |os, os_facts|
    ['cache/upload', 'cache/text'].each do |cluster|
      context "on #{os} (#{cluster})" do
        let(:facts) { os_facts }
        let(:node_params) {{ '_role' => cluster }}
        # this only applies to prod instances otherwise $fe_mem_gb is 1
        let(:params) {{'check_min_fe_mem' => false}}
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
