require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::common' do
  let(:pre_condition) { 'class { "::apt": }' }
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          'home_dir' => '/home/cephuser',
          'ceph_repository_component' => 'dummy/component-repo',
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { should contain_package('ceph-common') }
        it { should contain_package('fio') }
        it { is_expected.to contain_apt__package_from_component('ceph').with_component('dummy/component-repo') }
      end
    end
  end
end
