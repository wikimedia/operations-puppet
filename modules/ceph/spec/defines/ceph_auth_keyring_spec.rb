require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::auth::keyring', :type => :define do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'dummy_client' }
      let(:facts) { os_facts }
      let(:params) { {
        :keyring_path => '/path/to/dummy.keyring',
        :keydata      => 'dummykeyringdata',
        :caps         => {},
      } }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'Populates client and keydata' do
        it { is_expected.to contain_file('/path/to/dummy.keyring').with_content(
          /^\[client.dummy_client\]/
        ).with_content(
          /^\s*key = dummykeyringdata/
        ) }
      end

      describe 'Populates capabilities' do
        let(:params) { super().merge(caps: {
            "mon" => "some-mon-capabilities",
            "mgr" => "some-mgr-capabilities",
        }) }
        it { is_expected.to contain_file('/path/to/dummy.keyring').with_content(
          /^\s*caps mon = "some-mon-capabilities"$/
        ).with_content(
          /^\s*caps mgr = "some-mgr-capabilities"$/
        ) }
      end

      describe 'Imports the keyring if import_to_ceph true' do
        let(:params) { super().merge(
          import_to_ceph: true,
          caps: {
            "mon" => "some-mon-capabilities",
            "mgr" => "some-mgr-capabilities",
          }
        ) }
        it { is_expected.to contain_exec('ceph-auth-load-key-dummy_client').with_command(
            "/usr/bin/ceph --in-file '/path/to/dummy.keyring' auth import"
        ).with_unless(
            "/usr/bin/ceph --in-file '/path/to/dummy.keyring' auth get-or-create-key 'client.dummy_client' mon " \
            "'some-mon-capabilities' mgr 'some-mgr-capabilities'"
        ) }
      end

      describe 'does not install the verification script if it imports nothing' do
        it { is_expected.to_not contain_class('ceph::auth::verify') }
        it { is_expected.to_not contain_file('/usr/local/sbin/verify-cephx-keys') }
      end

      describe 'installs the verification script if it imports to the cluster' do
        let(:params) { super().merge(import_to_ceph: true) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('ceph::auth::verify') }
        it { is_expected.to contain_file('/usr/local/sbin/verify-cephx-keys') }
      end

      describe 'manages the key material by default' do
        let(:params) { super().merge(
          import_to_ceph: true,
          caps: { "mon" => "some-mon-capabilities" }
        ) }
        it { is_expected.to contain_file('/path/to/dummy.keyring').with_replace(true) }
        it { is_expected.to contain_exec('ceph-auth-load-key-dummy_client') }
      end

      describe 'leaves the key material alone if manage_keydata false' do
        let(:params) { super().merge(
          import_to_ceph: true,
          manage_keydata: false,
          caps: { "mon" => "some-mon-capabilities" }
        ) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/path/to/dummy.keyring').with_replace(false) }
        it { is_expected.to_not contain_exec('ceph-auth-load-key-dummy_client') }
      end

      describe 'passes owner, group and mode through' do
        let(:params) { super().merge({
          'owner' => 'dummy_owner',
          'group' => 'dummy_group',
          'mode' => '000',
        })}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/path/to/dummy.keyring')
          .with_owner('dummy_owner')
          .with_group('dummy_group')
          .with_mode('000')
        }
      end

      describe 'does not prepend "client." if the key name has a dot already' do
        let(:title) { 'mon.dummy_client' }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/path/to/dummy.keyring')
          .with_content(/^\[mon.dummy_client\]/)
        }
      end

      describe 'generates the correct keypath if none passed' do
        let(:params) {{
          :keydata => "dummykeydata",
          :caps    => {}
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/ceph/ceph.client.dummy_client.keyring') }
      end

      describe 'uses generated client name for the generated keypath if none passed' do
        let(:title) { 'mon.dummy_client' }
        let(:params) {{
          :keydata => "dummykeydata",
          :caps    => {}
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/ceph/ceph.mon.dummy_client.keyring') }
      end
    end
  end
end
