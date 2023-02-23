require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::backy2' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:params) {{
        'cluster_name' => 'dummy_cluster',
        'data_dir' => '/dummy/data/dir',
        'ceph_vm_pool' => 'dummy_ceph_vm_pool',
        'backup_interval' => '*-*-* 1:00:00',
      }}
      let(:pre_condition) {
        "class { '::ceph::common':
          home_dir => '/home/dir',
          ceph_repository_component => 'dummy/component-repo',
        }"
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      }) }
      let(:node_params) {{ '_role' => 'wmcs::backy2' }}
      it { is_expected.to compile.with_all_deps }
    end
  end
end
