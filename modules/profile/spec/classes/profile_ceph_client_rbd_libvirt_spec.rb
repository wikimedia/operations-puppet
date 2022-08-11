require_relative "../../../../rake_modules/spec_helper"

describe "profile::ceph::client::rbd_libvirt" do
  let(:pre_condition) {
    'class { "::apt": }
     class { "::prometheus::node_exporter": }'
  }
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      base_params = {
        "enable_v2_messenger" => true,
        "mon_hosts" => {
          "monhost01.local" => {
            "public" => {
              "addr" => "127.0.10.1",
            },
          },
          "monhost02.local" => {
            "public" => {
              "addr" => "127.0.10.2",
            },
          },
        },
        "osd_hosts" => {
          "osdhost01.local" => {
            "public" => {
              "addr" => "127.0.11.1",
            },
          },
        },
        "cluster_networks" => ["192.168.4.0/22"],
        "public_networks" => ["10.192.20.0/24"],
        "data_dir" => "/data/dir",
        "client_name" => "dummy_client_name",
        "cinder_client_name" => "dummy_cinder_client_name",
        "fsid" => "dummyfsid-17bc-44dc-9aeb-1d044c9bba9e",
        "libvirt_rbd_uuid" => "dummy_libvirt_rbd_uuid",
        "libvirt_rbd_cinder_uuid" => "dummy_libvirt_rbd_cinder_uuid",
        "ceph_auth_conf" => {
          "dummy_client_name" => {
            "keydata" => "dummykeydata",
            "caps" => {
              "mon" => "whatever",
            },
          },
          "dummy_cinder_client_name" => {
            "keydata" => "dummykeydatacinder",
            "caps" => {
              "mon" => "whatever",
            },
          },
        },
      }
      let(:facts) { facts }
      let(:params) { base_params }

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
