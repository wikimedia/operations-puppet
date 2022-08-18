require_relative "../../../../rake_modules/spec_helper"

describe "profile::ceph::osd" do
  let(:pre_condition) {
    'class { "::apt": }
     class { "::prometheus::node_exporter": }'
  }
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      before(:each) do
        Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |_| "127.0.0.10" }
      end
      base_params = {
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
        "num_os_disks" => 2,
        "disk_models_without_write_cache" => ["matchingmodel"],
        "disks_io_scheduler" => "dummy_io_scheduler",
        "cinder_backup_nodes" => ["cloudbackupxxxx.example.com"],
        "cluster_networks" => [],
      }
      let(:facts) {
        facts.merge({
          "fqdn" => "dummyhost1",
        })
      }
      let(:params) { base_params }
      let(:node_params) { { "_role" => "ceph::osd" } }
      it { is_expected.to compile.with_all_deps }

      context "when less/equal disks than os disks it does nothing" do
        let(:facts) {
          super().merge({
            "fqdn" => "dummyhost1",
            "num_os_disks" => 1,
            "disks" => {
              "sda" => {
                "size_bytes" => 1,
              },
            },

          })
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_exec(/Disable write cache on device/) }
        it { is_expected.not_to contain_exec(/Set IO scheduler on device /) }
      end

      context "when more disks than num_os_disks" do
        let(:params) {
          super().merge({
            "num_os_disks" => 1,
          })
        }

        context "when empty disks fact" do
          let(:facts) {
            super().merge({
              "fqdn" => "dummyhost1",
              "disks" => {},
            })
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec(/Disable write cache on device/) }
          it { is_expected.not_to contain_exec(/Set IO scheduler on device /) }
        end

        context "when non empty disks fact and no model does not disable write caches" do
          let(:facts) {
            super().merge({
              "fqdn" => "dummyhost1",
              "disks" => {
                "sda" => {
                  "size_bytes" => 1,
                },
                "sdb" => {
                  "size_bytes" => 2,
                },
                "sdc" => {
                  "size_bytes" => 2,
                },
              },
            })
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sda") }
          it { is_expected.not_to contain_exec("Set IO scheduler on device /dev/sda to dummy_io_scheduler") }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sdb") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdb to dummy_io_scheduler") }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sdc") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdc to dummy_io_scheduler") }
        end

        context "when non empty disks fact and non matching model does not disable write caches" do
          let(:facts) {
            super().merge({
              "fqdn" => "dummyhost1",
              "disks" => {
                "sda" => {
                  "size_bytes" => 1,
                },
                "sdb" => {
                  "size_bytes" => 2,
                  "model" => "idontmatch",
                },
                "sdc" => {
                  "size_bytes" => 2,
                  "model" => "idontmatch",
                },
              },
            })
          }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sda") }
          it { is_expected.not_to contain_exec("Set IO scheduler on device /dev/sda to dummy_io_scheduler") }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sdb") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdb to dummy_io_scheduler") }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sdc") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdc to dummy_io_scheduler") }
        end

        context "when non empty disks fact and matching model disables caches" do
          let(:facts) {
            super().merge({
              "fqdn" => "dummyhost1",
              "disks" => {
                "sda" => {
                  "size_bytes" => 1,
                },
                "sdb" => {
                  "size_bytes" => 2,
                  "model" => "matchingmodel",
                },
                "sdc" => {
                  "size_bytes" => 2,
                  "model" => "matchingmodel",
                },
              },
            })
          }
          it { is_expected.not_to contain_exec("Disable write cache on device /dev/sda") }
          it { is_expected.not_to contain_exec("Set IO scheduler on device /dev/sda to dummy_io_scheduler") }
          it { is_expected.to contain_exec("Disable write cache on device /dev/sdb") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdb to dummy_io_scheduler") }
          it { is_expected.to contain_exec("Disable write cache on device /dev/sdc") }
          it { is_expected.to contain_exec("Set IO scheduler on device /dev/sdc to dummy_io_scheduler") }
        end
      end

      context "when no ceph repo passed uses correct default" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository("repository_ceph").with_components("thirdparty/ceph-octopus") }
      end

      context "when ceph repo passed uses the given one" do
        let(:params) {
          super().merge({
            "ceph_repository_component" => "dummy/component-repo",
          })
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_apt__repository("repository_ceph").with_components("dummy/component-repo") }
      end

      context "when multiple cluster_networks specificed, adds the gateways for the ones not local" do
        let(:params) {
          super().merge({
            "cluster_networks" => ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "192.168.4.0/24"],
          })
        }
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_interface__route("route_to_192_168_1_0")
                           .with_address("192.168.1.0")
                           .with_nexthop("192.168.4.254")
        }
        it {
          is_expected.to contain_interface__route("route_to_192_168_2_0")
                           .with_address("192.168.2.0")
                           .with_nexthop("192.168.4.254")
        }
        it {
          is_expected.to contain_interface__route("route_to_192_168_3_0")
                           .with_address("192.168.3.0")
                           .with_nexthop("192.168.4.254")
        }
        it { is_expected.not_to contain_interface__route("route_to_192_168_4_0") }
      end
    end
  end
end
