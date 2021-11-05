require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::auth::load_all' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          :configuration => {
            'client1' => {
              'keydata' => 'dummy_keydata',
              'keyring_path' => '/etc/ceph/my_keyring.keyring',
              'caps' => {
                'osd' => 'my osd_caps',
                'mon' => 'my mon_caps',
              }
            }
          },
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'Loads multiple keys' do
        let(:params) { super().merge({
          :configuration => {
            'client1' => {
              'keydata' => 'dummy_keydata1',
              'keyring_path' => '/etc/ceph/client1.keyring',
              'caps' => {
                'mon' => 'my mon_caps',
              }
            },
            'client2' => {
              'keydata' => 'dummy_keydata2',
              'keyring_path' => '/etc/ceph/client2.keyring',
              'caps' => {
                'mon' => 'my mon_caps',
              }
            }
        }})}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_ceph__auth__keyring('client1') }
        it { is_expected.to contain_ceph__auth__keyring('client2') }
      end

      describe 'Fills up correct keyring_path if none passed' do
        let(:params) { super().merge({
          :configuration => {
            'client1' => {
              'keydata' => 'dummy_keydata1',
              'caps' => {
                'mon' => 'my mon_caps',
              }
            }
        }})}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_ceph__auth__keyring('client1')
          .with_keyring_path('/etc/cept/ceph.client.client1.keyring')
        }
      end

      describe 'Discards a key if it has no keydata' do
        let(:params) { super().merge({
          :configuration => {
            'client1' => {
              'caps' => {
                'mon' => 'my mon_caps',
              }
            }
        }})}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_ceph__auth__keyring('client1')}
      end
    end
  end
end
