# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::osd', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'c0e23s0' }
      let(:facts) { os_facts }
      let(:params) { {
        :fsid         => 'dummy-fsid',
        :device       => '/dev/disk/by-id/wwn-0x5000c500d9bb2bb5',
        :device_class => 'hdd'
      } }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end
      # rubocop:disable Metrics/LineLength
      describe 'create hdd osd without bluestore db' do
        it { is_expected.to contain_exec('ceph-osd-check-fsid-mismatch-c0e23s0')
                              .with_before('["Exec[ceph-osd-prepare-c0e23s0]"]') }
        it { is_expected.to contain_exec('ceph-osd-prepare-c0e23s0')
                              .with_before('["Exec[ceph-osd-activate-c0e23s0]"]') }
        it { is_expected.to contain_exec('ceph-osd-activate-c0e23s0')
                              .with_unless("id=$(ceph-volume lvm list /dev/disk/by-id/wwn-0x5000c500d9bb2bb5 --format=json | jq -r keys[]) systemctl is-active ceph-osd@\$id") }
      end
      describe 'create hdd osd with bluestore db' do
        let(:params) { super().merge(:bluestore_db => '/dev/nvme0n1p1') }
        it { is_expected.to contain_exec('ceph-osd-prepare-c0e23s0')
                              .with_command("ceph-volume lvm prepare --bluestore --data /dev/disk/by-id/wwn-0x5000c500d9bb2bb5 --block.db /dev/nvme0n1p1 --crush-device-class hdd") }
      end
      describe 'create ssd osd' do
        let(:params) { super().merge(:device_class => 'ssd') }
        it { is_expected.to contain_exec('ceph-osd-prepare-c0e23s0')
                              .with_command("ceph-volume lvm prepare --bluestore --data /dev/disk/by-id/wwn-0x5000c500d9bb2bb5  --crush-device-class ssd") }
      end

      describe 'remove osd' do
        let(:params) { super().merge(:ensure => "absent") }
        it { is_expected.to contain_exec('remove-osd-c0e23s0')
                              .with_onlyif("ceph-volume lvm list /dev/disk/by-id/wwn-0x5000c500d9bb2bb5") }
      end
    end
  end
end
