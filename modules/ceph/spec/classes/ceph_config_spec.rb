require_relative "../../../../rake_modules/spec_helper"

describe "ceph::config" do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) {
        "class { '::apt': }
        class { '::ceph::common':
          home_dir => '/home/dir',
          ceph_repository_component => 'dummy/component-repo',
        }"
      }
      let(:facts) { facts }
      base_params = {
        "enable_libvirt_rbd" => true,
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
        "cluster_networks" => ["192.168.4.0/24", "192.168.5.0/24"],
        "public_networks" => ["10.192.20.0/24", "10.192.64.0/24"],
        "fsid" => "dummyfsid-17bc-44dc-9aeb-1d044c9bba9e",
        "osd_hosts" => {
          "osdhost01" => {
            "public" => {
              "addr" => "127.1.10.1",
              "iface" => "ens1f0np0",
            },
            "cluster" => {
              "addr" => "127.100.10.1",
              "prefix" => "24",
              "iface" => "ens1f0np1",
            },
          },
          "osdhost02" => {
            "public" => {
              "addr" => "127.1.10.2",
              "iface" => "ens2f0np0",
            },
            "cluster" => {
              "addr" => "127.100.10.2",
              "prefix" => "24",
              "iface" => "ens2f0np1",
            },
          },
        },
      }
      let(:params) { base_params }

      describe "compiles without errors" do
        it { is_expected.to compile.with_all_deps }
      end

      describe "it has the mon section defined" do
        it {
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(/^\[mon.monhost01\].*/)
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(/^\[mon.monhost02\]/)
        }
      end

      describe "it has the osd section defined" do
        it {
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(/^\[osd.osdhost01\]/)
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(/^\[osd.osdhost02\]/)
        }
      end

      describe "it has the initial members section defined" do
        it {
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(/mon initial members = monhost01,monhost02/)
        }
      end

      describe "it has the public networks defined" do
        it {
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(%r{public network = 10.192.20.0/24 10.192.64.0/24})
        }
      end

      describe "it has the cluster networks defined" do
        it {
          is_expected.to contain_file("/etc/ceph/ceph.conf").with_content(%r{cluster network = 192.168.4.0/24 192.168.5.0/24})
        }
      end

      describe "if libvirtd_rbd is enabled" do
        let(:params) {
          base_params.merge({
            "enable_libvirt_rbd" => true,
          })
        }
        it { should contain_package("python-rbd") }
        it { should contain_package("qemu-block-extra") }
      end

      describe "if libvirtd_rbd is disabled" do
        let(:params) {
          base_params.merge({
            "enable_libvirt_rbd" => false,
          })
        }
        it { should_not contain_package("python-rbd") }
        it { should_not contain_package("qemu-block-extra") }
      end
    end
  end
end
