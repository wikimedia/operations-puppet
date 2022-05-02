require_relative '../../../../rake_modules/spec_helper'

describe 'profile::etcd::tlsproxy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        'class passwords::etcd {
          $accounts = {
            "root"     => "Wikipedia",
            "conftool" => "another_secret",
          }
        }'
      end

      let(:params) {
        {
          cert_name: 'etcd-v3.eqiad.wmnet',
          acls: { '/conftool' => ['root', 'conftool'] },
          salt: 'salt1234',
          read_only: false,
          listen_port: 4001,
          upstream_port: 2379,
          tls_upstream: true,
          pool_pwd_seed: 'seed'
        }
      }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
