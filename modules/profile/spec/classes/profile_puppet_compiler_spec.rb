require_relative '../../../../rake_modules/spec_helper'
describe 'profile::puppet_compiler' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node_params) {{'realm' => 'labs'}}
      let(:params) do
        {
          puppetdb_host: 'puppetdb.example.org',
          puppetdb_port: 8080,
          web_frontend: true
        }
      end
      let(:pre_condition) do
        "
        labstore::nfs_mount{project-on-labstore-secondary:
          mount_path => '/foo',
          mount_name => 'foo',
        }
        "
      end

      it { is_expected.to compile.with_all_deps }
    end
  end
end
