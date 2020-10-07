require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9', '10'],
    }
  ]
}

describe 'profile::etcd::tlsproxy' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      # Patch the secret function, we don't care about it
      before(:each) do
        Puppet::Parser::Functions.newfunction(:secret) { |_|
          'expected value'
        }
      end
      let(:pre_condition) {
'class passwords::etcd {
    $accounts = {
        "root"     => "Wikipedia",
        "conftool" => "another_secret",
    }
}'
      }
      let(:node_params) { {site: 'eqiad', test_name: 'etcd_tlsproxy', numa_networking: 'off', realm: 'production'} }
      let(:facts) {
        facts.merge(
          {
            initsystem: 'systemd',
            numa: { device_to_htset: {lo: []}, device_to_node: {lo: ["a"]}}
          }
        )
      }

      let(:params) {
        {
          cert_name: 'etcd.eqiad.wmnet',
          acls: { '/conftool' => ['root', 'conftool'] },
          salt: 'salt',
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
