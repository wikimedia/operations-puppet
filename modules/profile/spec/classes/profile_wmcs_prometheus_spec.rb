require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::prometheus' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts  }
      let(:params) { { } }
      let(:node_params) {{ '_role' => 'wmcs/prometheus' }}
      let(:pre_condition) do
        " define prometheus::class_config ($dest, $site, $class_name, $port, $labels = undef) {}
        service{'apache2':} "
      end

      context "when storage_retention_size is not passed" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_prometheus__server('labs').with_storage_retention_size(nil) }
      end

      context "when storage_retention_size is passed" do
        let(:params) { super().merge({
          'storage_retention_size' => '50GB'
        }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_prometheus__server('labs').with_storage_retention_size('50GB') }
      end
    end
  end
end
