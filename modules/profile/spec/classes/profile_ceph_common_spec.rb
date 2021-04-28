require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::common' do
  let(:pre_condition) { 'class { "::apt": }' }
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      base_params = {
        'data_dir' => '/data/dir',
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      })  }
      let(:params) { base_params }
      let(:node_params) {{ '_role' => 'ceph::common' }}
      it { is_expected.to compile.with_all_deps }

      context "when no ceph repo passed uses correct default" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository('repository_ceph').with_components('thirdparty/ceph-octopus') }
      end

      context "when ceph repo passed uses the given one" do
        let(:params) { base_params.merge({
          'ceph_repository_component' => 'dummy/component-repo'
        }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository('repository_ceph').with_components('dummy/component-repo') }
      end
    end
  end
end
