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
    end
  end
end
