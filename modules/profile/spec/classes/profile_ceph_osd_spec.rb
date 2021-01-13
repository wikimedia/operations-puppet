require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::osd' do
  # TODO: support debian 10
  on_supported_os(WMFConfig.test_on(9, 9)).each do |os, facts|
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
        }
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      }) }
      let(:node_params) {{ '_role' => 'ceph::osd' }}
      let(:params) { base_params }
      it { is_expected.to compile.with_all_deps }

      context "when empty disks fact" do
        let(:facts) { facts.merge({
          'fqdn' => 'dummyhost1',
          'disks' => {}
        }) }
        it { is_expected.to compile.with_all_deps }
      end

      context "when no disk model facts" do
        let(:facts) { facts.merge({
          'fqdn' => 'dummyhost1',
          'disks' => {
            'sda' => {}
          }
        }) }
        it { is_expected.to compile.with_all_deps }
      end

      context "when disk model write cache should be enabled" do
        let(:params) { base_params.merge({
          'disk_models_without_write_cache' => ['imnotdummymodel']
        }) }
        let(:facts) { facts.merge({
          'fqdn' => 'dummyhost1',
          'disks' => {
            'sda' => {
              'model' => 'dummymodel',
            }
          }
        }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_exec('Disable write cache on device /dev/sda') }
      end

      context "when disk model is supported" do
        let(:facts) { facts.merge({
          'fqdn' => 'dummyhost1',
          'disks' => {
            'sda' => {
              'model' => 'dummymodel',
            }
          }
        }) }
        let(:params) { base_params.merge({
          'disk_models_without_write_cache' => ['dummymodel']
        }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('Disable write cache on device /dev/sda') }
      end
    end
  end
end
