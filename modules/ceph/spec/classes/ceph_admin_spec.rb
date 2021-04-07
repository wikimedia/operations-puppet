require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::admin' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) {
        "class { '::ceph::config':
          enable_libvirt_rbd => true,
          enable_v2_messenger => true,
          mon_hosts => {},
          cluster_network => '192.168.4.0/22',
          public_network => '10.192.20.0/24',
          fsid => 'dummyfsid-17bc-44dc-9aeb-1d044c9bba9e',
        }
        class { '::ceph::common':
          home_dir => '/home/dir'
        }"
      }
      let(:facts) { facts }
      let(:params) do
        {
          admin_keyring: '/path/to/admin/keyring',
          data_dir: '/path/to/datadir',
          admin_keydata: 'someadminkeydata',
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { should contain_package('ceph') }
      end
    end
  end
end
