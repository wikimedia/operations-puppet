# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "nftables::client" do
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
      let(:title) { "test_client" }
      let(:params) { { proto: "tcp", desc: "some desc", port: [443, 80] } }

      describe "basic destination filter with QOS" do
        let(:params) do
          super().merge(dst_ips: %w[192.0.2.1 fe80::1], qos: "low")
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            "/etc/nftables/output/10_test_client.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 192.0.2.1 } tcp dport { 80, 443 } accept
            ip6 daddr { fe80::1 } tcp dport { 80, 443 } accept
          EOF
        end
        it do
          is_expected.to contain_file(
            "/etc/nftables/postrouting/10_test_client_client_low.nft"
          ).with_content(<<~'EOF')
            # Managed by puppet
            # some desc
            ip daddr { 192.0.2.1 } tcp dport { 80, 443 } ip dscp set cs1 return
            ip6 daddr { fe80::1 } tcp dport { 80, 443 } ip6 dscp set cs1 return
          EOF
        end
      end
    end
  end
end
