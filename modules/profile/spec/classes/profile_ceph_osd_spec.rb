require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::osd' do
  let(:pre_condition) { 'class { "::apt": }' }
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      base_params = {
        'bootstrap_keydata' => 'NOTAREALKEY==',
        'osd_hosts' => {
          'dummyhost1' => {
            'public'  => {
              'addr'  => '10.64.20.66',
              'iface' => 'ens3f0np0',
            },
            'cluster'  => {
              'addr'   => '192.168.4.15',
              'prefix' => '24',
              'iface'  => 'ens3f1np1',
            }
          }
        },
        'disk_models_without_write_cache' => ['matchingmodel'],
        'os_disks' => [],
        'disks_io_scheduler' => 'dummy_io_scheduler',
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      })  }
      let(:params) { base_params }
      let(:node_params) {{ '_role' => 'ceph::osd' }}
      it { is_expected.to compile.with_all_deps }

      context "when empty os_disks" do
        let(:params) { base_params.merge({
          'os_disks' => []
        }) }

        context "when empty disks fact" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {}
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec(/Disable write cache on device/) }
          it { is_expected.not_to contain_exec(/Set IO scheduler on device /) }
        end

        context "when non empty disks fact and no model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {}
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end

        context "when non empty disks fact and non matching model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {
                'model' => 'idontmatch',
              }
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end

        context "when non empty disks fact and matching model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {
                'model' => 'matchingmodel',
              }
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end
      end

      context "when non empty os_disks" do
        let(:params) { base_params.merge({
          'os_disks' => ['sda'],
        }) }

        context "when empty disks fact" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {}
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec(/Disable write cache on device/) }
          it { is_expected.not_to contain_exec(/Set IO scheduler on device /) }
        end

        context "when non empty disks fact and no model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {}
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.not_to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end

        context "when non empty disks fact and non matching model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {
                'model' => 'idontmatch',
              }
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.not_to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end

        context "when non empty disks fact and matching model" do
          let(:facts) { facts.merge({
            'fqdn' => 'dummyhost1',
            'disks' => {
              'sda' => {
                'model' => 'matchingmodel',
              }
            }
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
          it { is_expected.not_to contain_exec('Set IO scheduler on device /dev/sda to dummy_io_scheduler') }
        end
      end

      context "when no ceph repo passed uses correct default" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository('repository_ceph').with_components('thirdparty/ceph-nautilus-buster') }
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
