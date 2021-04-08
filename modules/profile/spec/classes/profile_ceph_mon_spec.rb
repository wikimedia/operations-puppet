require_relative '../../../../rake_modules/spec_helper'

describe 'profile::ceph::mon' do
  let(:pre_condition) { 'class { "::apt": }' }
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| '127.0.0.10' }
      end
      base_params = {
        'prometheus_nodes' => ['dummyprometheus1.local.lo'],
        'openstack_controllers' => ['dummyprometheus1.local.lo'],
        'mon_hosts' => {
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
        },
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
        },
        'admin_keyring' => '/path/to/adming.keyring',
        'cluster_network' => '192.168.4.0/22',
        'public_network' => '10.192.20.0/24',
        'data_dir' => '/path/to/data',
        'admin_keydata' => 'NOTAREALKEYADMIN==',
        'fsid' => 'dummy_fsid',
        'mon_keydata' => 'NOTAREALKEY==',
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      })  }
      let(:params) { base_params }
      let(:node_params) {{ '_role' => 'ceph::mon' }}
      it { is_expected.to compile.with_all_deps }

      context "when no ceph repo passed uses correct default" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository('repository_ceph').with_components('thirdparty/ceph-nautilus-buster') }
      end

      context "when ceph repo passed uses the given one" do
        let(:params) { base_params.merge({
          'ceph_repository_component' => 'dummy/component-repo'
        }) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository('repository_ceph').with_components('dummy/component-repo') }
      end
    end
  end
end
