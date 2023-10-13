require_relative '../../../../rake_modules/spec_helper'
describe 'profile::base' do
  on_supported_os(WMFConfig.test_on(11)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node_params) {{ '_role' => 'sretest' }}
      describe 'defaults' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
