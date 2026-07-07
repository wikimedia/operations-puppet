# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "nftables::service" do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "include nftables
         nftables::set { 'src_set1':
            hosts => [ '1.1.1.1', 'fe::111' ],
         }
         nftables::set { 'src_set2':
            hosts => [ '1.1.1.2', 'fe::112' ],
         }
         nftables::set { 'dst_set1':
            hosts => [ '1.1.1.3', 'fe::113' ],
         }
         nftables::set { 'dst_set2':
            hosts => [ '1.1.1.4', 'fe::114' ],
         }
        "
      end
      let(:title) { "test_service" }
      let(:params) { { proto: "tcp", desc: "some desc", port: [443, 80] } }

      describe "multiple udp ports" do
        let(:params) { super().merge(proto: "udp", port: [444, 53, 333]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            udp dport { 53, 333, 444 } accept
          EOF
        end
      end

      describe "tcp port range" do
        let(:params) { super().merge(port: [], port_range: [8000, 9000]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport 8000-9000 accept
          EOF
        end
      end

      describe "single port as integer, no array" do
        let(:params) { super().merge(port: 1234) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport { 1234 } accept
          EOF
        end
      end

      describe "custom prio - small number" do
        let(:params) { super().merge(port: [80], prio: 3) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/03_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport { 80 } accept
          EOF
        end
      end

      describe "custom prio - long number" do
        let(:params) { super().merge(port: [80], prio: 99) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/99_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport { 80 } accept
          EOF
        end
      end

      describe "source IPs with some ports" do
        let(:params) do
          super().merge(src_ips: %w[10.0.0.10 10.0.0.20 fe::80 fe::90])
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 10.0.0.10, 10.0.0.20 } tcp dport { 80, 443 } accept
            ip6 saddr { fe::80, fe::90 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "destination IPs with some ports" do
        let(:params) do
          super().merge(dst_ips: %w[10.0.0.20 10.0.0.10 fe::90 fe::80])
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 10.0.0.10, 10.0.0.20 } tcp dport { 80, 443 } accept
            ip6 daddr { fe::80, fe::90 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "both src and dst IPs with some ports" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_ips: %w[2.0.0.2 fe::80]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } ip daddr { 2.0.0.2 } tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr { fe::80 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only, single src" do
        let(:params) { super().merge(src_ips: ["1.0.0.1"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only, multiple src" do
        let(:params) { super().merge(src_ips: %w[1.0.0.1 1.0.0.2]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1, 1.0.0.2 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only, single dst" do
        let(:params) { super().merge(dst_ips: ["1.0.0.1"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 1.0.0.1 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only, multiple dst" do
        let(:params) { super().merge(dst_ips: %w[1.0.0.1 1.0.0.2]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 1.0.0.1, 1.0.0.2 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only, mixed src/dst" do
        let(:params) do
          super().merge(
            src_ips: %w[1.1.1.1 1.1.1.2],
            dst_ips: %w[2.2.2.2 2.2.2.3]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.1.1.1, 1.1.1.2 } ip daddr { 2.2.2.2, 2.2.2.3 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 only source, IPv4+IPv6 dst, T351094" do
        let(:params) do
          super().merge(
            src_ips: ["192.0.2.1"],
            dst_ips: %w[192.0.2.2 fe80::100]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 192.0.2.1 } ip daddr { 192.0.2.2 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 only, single src" do
        let(:params) { super().merge(src_ips: ["fe::100"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 saddr { fe::100 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 only, multiple src" do
        let(:params) { super().merge(src_ips: ["fe::100"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 saddr { fe::100 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 only, single dst" do
        let(:params) { super().merge(dst_ips: ["fe::100"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 daddr { fe::100 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 only, multiple dst" do
        let(:params) { super().merge(dst_ips: ["fe::100"]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 daddr { fe::100 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 raw src and some dst sets" do
        let(:params) do
          super().merge(
            src_ips: %w[fe::90 fe::80],
            dst_sets: %w[dst_set1 dst_set2]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 saddr { fe::80, fe::90 } ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr { fe::80, fe::90 } ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 raw src and some dst sets" do
        let(:params) do
          super().merge(
            src_ips: %w[1.1.1.2 1.1.1.1],
            dst_sets: %w[dst_set1 dst_set2]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.1.1.1, 1.1.1.2 } ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr { 1.1.1.1, 1.1.1.2 } ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv6 src sets and raw dst" do
        let(:params) do
          super().merge(
            src_sets: %w[src_set2 src_set1],
            dst_ips: %w[fe::90 fe::80]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip6 saddr @src_set1_ipv6 ip6 daddr { fe::80, fe::90 } tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr { fe::80, fe::90 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "IPv4 src sets and raw dst" do
        let(:params) do
          super().merge(
            src_sets: %w[src_set2 src_set1],
            dst_ips: %w[2.2.2.2 1.1.1.1]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 ip daddr { 1.1.1.1, 2.2.2.2 } tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr { 1.1.1.1, 2.2.2.2 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6, source sets" do
        let(:params) { super().merge(src_sets: %w[src_set2 src_set1]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6, dest sets" do
        let(:params) { super().merge(dst_sets: %w[dst_set2 dst_set1]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6, both sets" do
        let(:params) do
          super().merge(
            src_sets: %w[src_set2 src_set1],
            dst_sets: %w[dst_set2 dst_set1]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set1_ipv4 ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6 with raw IPs and dst sets, with some ports" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_sets: %w[dst_set1 dst_set2]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr { 1.0.0.1 } ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6 with raw IPs and dst sets, with some ports" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_sets: %w[dst_set1 dst_set2]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr { 1.0.0.1 } ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Mixed IPv4/IPv6 with all possible combinations" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_ips: %w[2.2.2.2 fe::100],
            src_sets: %w[src_set1 src_set2],
            dst_sets: %w[dst_set1 dst_set2]
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set1_ipv4 ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set1_ipv4 ip daddr { 2.2.2.2 } tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip saddr @src_set2_ipv4 ip daddr { 2.2.2.2 } tcp dport { 80, 443 } accept
            ip saddr { 1.0.0.1 } ip daddr @dst_set1_ipv4 tcp dport { 80, 443 } accept
            ip saddr { 1.0.0.1 } ip daddr @dst_set2_ipv4 tcp dport { 80, 443 } accept
            ip saddr { 1.0.0.1 } ip daddr { 2.2.2.2 } tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set1_ipv6 ip6 daddr { fe::100 } tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr @src_set2_ipv6 ip6 daddr { fe::100 } tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set1_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr @dst_set2_ipv6 tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr { fe::100 } tcp dport { 80, 443 } accept
          EOF
        end
      end

      describe "Empty list of source IPs" do
        let(:params) { super().merge(src_ips: []) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
        end
      end

      describe "Empty list of source sets" do
        let(:params) { super().merge(src_sets: []) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
        end
      end

      describe "Empty list of destination IPs" do
        let(:params) { super().merge(dst_ips: []) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
        end
      end

      describe "Empty list of destination sets" do
        let(:params) { super().merge(dst_sets: []) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
        end
      end
      describe "QOS destination IPs with some ports" do
        let(:params) do
          super().merge(
            dst_ips: %w[10.0.0.20 10.0.0.10 fe::90 fe::80],
            qos: "high"
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 10.0.0.10, 10.0.0.20 } tcp dport { 80, 443 } accept
            ip6 daddr { fe::80, fe::90 } tcp dport { 80, 443 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/postrouting/10_test_service_service_high.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 10.0.0.10, 10.0.0.20 } tcp sport { 80, 443 } ip dscp set af21 return
            ip6 saddr { fe::80, fe::90 } tcp sport { 80, 443 } ip6 dscp set af21 return
          EOF
        end
      end
      describe "QOS rsyncd" do
        let(:params) do
          super().merge(
            src_ips: %w[
              208.80.153.7
              208.80.154.13
              208.80.154.144
              2620:0:860:1:208:80:153:7
              2620:0:861:1:208:80:154:13
              2620:0:861:2:208:80:154:144
            ],
            proto: "tcp",
            desc: "some desc",
            port: [873, 1873],
            qos: "low"
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 208.80.153.7, 208.80.154.13, 208.80.154.144 } tcp dport { 873, 1873 } accept
            ip6 saddr { 2620:0:860:1:208:80:153:7, 2620:0:861:1:208:80:154:13, 2620:0:861:2:208:80:154:144 } tcp dport { 873, 1873 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/postrouting/10_test_service_service_low.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 208.80.153.7, 208.80.154.13, 208.80.154.144 } tcp sport { 873, 1873 } ip dscp set cs1 return
            ip6 daddr { 2620:0:860:1:208:80:153:7, 2620:0:861:1:208:80:154:13, 2620:0:861:2:208:80:154:144 } tcp sport { 873, 1873 } ip6 dscp set cs1 return
          EOF
        end
      end
      describe "QOS destination IPs and src ips" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_ips: %w[2.0.0.2 fe::80],
            qos: "high"
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } ip daddr { 2.0.0.2 } tcp dport { 80, 443 } accept
            ip6 saddr { fe::90 } ip6 daddr { fe::80 } tcp dport { 80, 443 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/postrouting/10_test_service_service_high.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 2.0.0.2 } ip daddr { 1.0.0.1 } tcp sport { 80, 443 } ip dscp set af21 return
            ip6 saddr { fe::80 } ip6 daddr { fe::90 } tcp sport { 80, 443 } ip6 dscp set af21 return
          EOF
        end
      end
      describe "QOS Empty list of destination IPs" do
        let(:params) { super().merge(dst_ips: [], qos: "low") }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
          is_expected.not_to contain_file(
            "/etc/nftables/postrouting/10_test_service_service_low.nft"
          )
        end
      end
      describe "notrack no dst_ips" do
        let(:params) { super().merge(port: 443, dst_ips: [], notrack: true) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.not_to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          )
          is_expected.not_to contain_file(
            "/etc/nftables/notrack/10_test_service.nft"
          )
        end
      end
      describe "notrack single port" do
        let(:params) { super().merge(port: 443, notrack: true) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport { 443 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/notrack/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            tcp dport { 443 } notrack
          EOF
        end
      end
      describe "notrack src set" do
        let(:params) do
          super().merge(port: 443, src_sets: ["src_set1"], notrack: true)
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 tcp dport { 443 } accept
            ip6 saddr @src_set1_ipv6 tcp dport { 443 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/notrack/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr @src_set1_ipv4 tcp dport { 443 } notrack
            ip6 saddr @src_set1_ipv6 tcp dport { 443 } notrack
          EOF
        end
      end
      describe "notrack objectstorage set" do
        let(:params) do
          super().merge(
            port: 9000,
            src_ips: %w[
              10.192.12.6
              10.192.32.47
              10.192.48.42
              10.192.8.7
              2620:0:860:103:10:192:32:47
              2620:0:860:104:10:192:48:42
              2620:0:860:109:10:192:8:7
              2620:0:860:10d:10:192:12:6
            ],
            notrack: true
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 10.192.12.6, 10.192.32.47, 10.192.48.42, 10.192.8.7 } tcp dport { 9000 } accept
            ip6 saddr { 2620:0:860:103:10:192:32:47, 2620:0:860:104:10:192:48:42, 2620:0:860:109:10:192:8:7, 2620:0:860:10d:10:192:12:6 } tcp dport { 9000 } accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/notrack/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 10.192.12.6, 10.192.32.47, 10.192.48.42, 10.192.8.7 } tcp dport { 9000 } notrack
            ip6 saddr { 2620:0:860:103:10:192:32:47, 2620:0:860:104:10:192:48:42, 2620:0:860:109:10:192:8:7, 2620:0:860:10d:10:192:12:6 } tcp dport { 9000 } notrack
          EOF
        end
      end
    end
    # VRRP
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "include nftables
        "
      end
      let(:title) { "test_service" }
      let(:params) { { proto: "vrrp", desc: "some desc" } }

      describe "VRRP with v4 and v6 src ips" do
        let(:params) { super().merge(src_ips: %w[10.0.0.10 fe::80]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 10.0.0.10 } ip protocol vrrp accept
            ip6 saddr { fe::80 } ip6 nexthdr vrrp accept
          EOF
        end
      end
      describe "VRRP without src ips" do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip protocol vrrp accept
            ip6 nexthdr vrrp accept
          EOF
        end
      end
      describe "VRRP QOS destination IPs and src ips" do
        let(:params) do
          super().merge(
            src_ips: %w[1.0.0.1 fe::90],
            dst_ips: %w[2.0.0.2 fe::80],
            qos: "high"
          )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/input/10_test_service.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 1.0.0.1 } ip daddr { 2.0.0.2 } ip protocol vrrp accept
            ip6 saddr { fe::90 } ip6 daddr { fe::80 } ip6 nexthdr vrrp accept
          EOF
          is_expected.to contain_file(
            "/etc/nftables/postrouting/10_test_service_service_high.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip saddr { 2.0.0.2 } ip daddr { 1.0.0.1 } ip protocol vrrp ip dscp set af21 return
            ip6 saddr { fe::80 } ip6 daddr { fe::90 } ip6 nexthdr vrrp ip6 dscp set af21 return
          EOF
        end
      end
    end
  end
end
