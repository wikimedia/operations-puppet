require_relative '../../../../rake_modules/spec_helper'
describe 'profile::contacts' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with no role set' do
        it do
          is_expected.to compile
            .and_raise_error(/This profile is only valid for nodes using the role/)
        end
      end
      context 'with role set' do
        let(:node_params) {{ '_role' => 'sretest' }}

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
