require_relative '../../../../rake_modules/spec_helper'

describe 'profile::toolforge::prometheus' do
  on_supported_os(WMFConfig.test_on(10, 11)).each do |os, os_facts|
    context "on #{os}" do
      ['tools', 'toolsbeta'].each do |project|
        context "on project #{project}" do
          let(:facts) {
            os_facts.merge(
              {
                'labsproject' => project,
              }
            )
          }
          let(:params) { { } }
          let(:node_params) {{ '_role' => 'toolforge::prometheus' }}
          it { is_expected.to compile.with_all_deps }

          context "when no storage_retention_size passed, uses undef" do
            it { is_expected.to contain_prometheus__server('tools').with_storage_retention_size(nil) }
          end

          context "when no storage_retention_size passed passes it along" do
            let(:params) { super().merge({ 'storage_retention_size' => '120GB' }) }
            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_prometheus__server('tools').with_storage_retention_size('120GB') }
          end
        end
      end
    end
  end
end
