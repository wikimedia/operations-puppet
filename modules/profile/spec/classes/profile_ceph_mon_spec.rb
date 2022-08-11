require_relative "../../../../rake_modules/spec_helper"

describe "profile::ceph::mon" do
  let(:pre_condition) do
    [
      'class { "::apt": }',
      'class { "::prometheus::node_exporter": }',
      'ceph::auth::keyring { "admin": keydata => "dummy", caps => {mon => "allow *" }}',
      'ceph::auth::keyring { "mon.dummyhost1": keydata => "dummy", caps => {mon => "allow *" }}',
      'ceph::auth::keyring { "mgr.dummyhost1": keydata => "dummy", caps => {mon => "allow *" }}',
    ]
  end
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| "127.0.0.10" }
      end
      base_params = {
        "openstack_controllers" => ["dummyprometheus1.local.lo"],
        "mon_hosts" => {
          "dummyhost1" => {
            "public" => {
              "addr" => "10.64.20.66",
              "iface" => "ens3f0np0",
            },
            "cluster" => {
              "addr" => "192.168.4.15",
              "prefix" => "24",
              "iface" => "ens3f1np1",
            },
          },
        },
        "osd_hosts" => {
          "dummyhost1" => {
            "public" => {
              "addr" => "10.64.20.66",
              "iface" => "ens3f0np0",
            },
            "cluster" => {
              "addr" => "192.168.4.15",
              "prefix" => "24",
              "iface" => "ens3f1np1",
            },
          },
        },
        "cluster_networks" => ["192.168.4.0/22"],
        "public_networks" => ["10.192.20.0/24"],
        "data_dir" => "/path/to/data",
        "fsid" => "dummy_fsid",
        "cinder_backup_nodes" => ["cloudbackupxxxx.example.com"],
        "ceph_auth_conf" => {
          "mon.dummyhost1" => {
            "keyring_path" => "/whatever1",
            "keydata" => "dummykeydata",
            "caps" => {},
          },
          "mgr.dummyhost1" => {
            "keyring_path" => "/whatever1",
            "keydata" => "dummykeydata",
            "caps" => {},
          },
          "admin" => {
            "keyring_path" => "/whatever2",
            "keydata" => "dummykeydata",
            "caps" => {},
          },
        },
      }
      let(:facts) {
        facts.merge({
          "fqdn" => "dummyhost1",
        })
      }
      let(:node) { "dummyhost1.example.com" }
      let(:params) { base_params }
      let(:node_params) { { "_role" => "ceph::mon" } }
      it { is_expected.to compile.with_all_deps }

      context "when no ceph repo passed uses correct default" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository("repository_ceph").with_components("thirdparty/ceph-octopus") }
      end

      context "when ceph repo passed uses the given one" do
        let(:params) {
          base_params.merge({
            "ceph_repository_component" => "dummy/component-repo",
          })
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository("repository_ceph").with_components("dummy/component-repo") }
      end
    end
  end
end
