require_relative '../../../../rake_modules/spec_helper'
describe 'profile::cache::varnish::frontend' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    ['cache/upload', 'cache/text'].each do |cluster|
      context "on #{os} (#{cluster})" do
        let(:facts) { os_facts }
        let(:node_params) {{ '_role' => cluster }}

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
