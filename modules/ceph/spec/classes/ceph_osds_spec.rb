# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::osds' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) {
        "ceph::auth::keyring { admin:
                keydata        => keydata,
                caps           => {mds => test},
            }
        ceph::auth::keyring { bootstrap-osd:
          keydata        => keydata,
            caps           => {mds => test},
        }
        ceph::auth::keyring { 'osd.foo':
          keydata        => keydata,
            caps           => {mds => test},
        }
        class { '::ceph::common':
          home_dir => '/home/dir',
          ceph_repository_component => 'dummy/component-repo',
        }
        class { 'ceph::config':
          cluster_networks    => [],
          enable_libvirt_rbd  => false,
          enable_v2_messenger => true,
          fsid                => fsid,
          mon_hosts           => {},
          osd_hosts           => {},
          public_networks     => [],
        }"
      }
      facts_path = File.join(__dir__, 'osds_facts.yml')
      let(:facts) { os_facts.merge!(YAML.safe_load(File.read(facts_path))) }
      let(:params) do
        {
          :fsid => "ceph-fsid",
          :mon_hosts => {
            "mon1" => {},
            "mon2" => {},
            "mon3" => {},
          },
          :osd_hosts => {
            "foo.example.com" => {
              "public" => {
                "addr" => "127.0.0.3"
              }
            }
          },
          :absent_osds => ['c0e23s23'],
          :excluded_slots => ['c0/e23/s24', 'c0/e23/s25'],
          :discrete_bluestore_device => true,
          :bluestore_device_name => '/dev/nvme0n1'
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'disable disk cache' do
        it { is_expected.to contain_exec('Disable write cache on device /dev/sdm').with_command('hdparm -W 0 /dev/sdm') }
      end
      describe 'set IO schedulers on ssd and hdd' do
        it { is_expected.to contain_sysfs__parameters('scheduler_sdk').with_values({"block/sdk/queue/scheduler" => "mq-deadline"}) }
        it { is_expected.to contain_sysfs__parameters('scheduler_sda').with_values({"block/sda/queue/scheduler" => "none"}) }
      end
      describe 'partition nvme disk' do
        it { is_expected.to contain_package('parted') }
        it { is_expected.to contain_exec('Create partition db.c0e23s0 on /dev/nvme0n1')
                           .with_command('parted -s -a optimal /dev/nvme0n1 mkpart db.c0e23s0 ext4 0% 8%') }
      end
      describe 'create ceph osd with bluestore db' do
        it { is_expected.to contain_ceph__osd('c0e23s0').with_bluestore_db('/dev/disk/by-partlabel/db.c0e23s0') }
      end
      describe 'create ceph osd' do
        it { is_expected.to contain_ceph__osd('c0e23s16').without_bluestore_db }
      end
      describe 'remove ceph osd' do
        it { is_expected.to contain_ceph__osd('c0e23s23').with_ensure('absent') }
      end
      # Check that we increment the hexadecimal wwn value by one for a SAS solid-state drive
      describe 'create ceph osd on SAS solid-state drive' do
        it { is_expected.to contain_ceph__osd('c0e23s16').with_device('/dev/disk/by-id/wwn-0x58ce38ee21f3c50d') }
      end
      # Check that we increment the hexadecimal wwn value by three for a SAS hard drive
      describe 'create ceph osd on SAS hard drive' do
        it { is_expected.to contain_ceph__osd('c0e23s0').with_device('/dev/disk/by-id/wwn-0x5000c500d9bb2bb7') }
      end
      # Check that we do not increment the wwn value for a SATA drive
      describe 'create ceph osd on SATA drive' do
        it { is_expected.to contain_ceph__osd('c0e23s22').with_device('/dev/disk/by-id/wwn-0x58ce38ee21edcd78') }
      end
    end
  end
end
