# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'nftables::service' do
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
      let(:title) { 'test_service' }
      let(:params) do
        {
         proto: 'tcp',
         desc: 'some desc',
         port: [443, 80],
        }
      end

      describe 'multiple udp ports' do
        let(:params) { super().merge(proto: 'udp', port: [444, 53, 333]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content("# Managed by puppet\n# some desc\nudp dport { 53, 333, 444 } accept\n")
        end
      end

      describe 'tcp port range' do
        let(:params) { super().merge(port: [], port_range: [8000, 9000]) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content("# Managed by puppet\n# some desc\ntcp dport 8000-9000 accept\n")
        end
      end

      describe 'single port as integer, no array' do
        let(:params) { super().merge(port: 1234) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content("# Managed by puppet\n# some desc\ntcp dport { 1234 } accept\n")
        end
      end

      describe 'custom prio - small number' do
        let(:params) { super().merge(port: [80], prio: 3) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/03_test_service.nft')
            .with_content("# Managed by puppet\n# some desc\ntcp dport { 80 } accept\n")
        end
      end

      describe 'custom prio - long number' do
        let(:params) { super().merge(port: [80], prio: 99) }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/99_test_service.nft')
            .with_content("# Managed by puppet\n# some desc\ntcp dport { 80 } accept\n")
        end
      end

      describe 'source IPs with some ports' do
        let(:params) do
            super().merge(
              src_ips: ['10.0.0.10', '10.0.0.20', 'fe::80', 'fe::90']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s10.0.0.10,\s10.0.0.20\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::80,\sfe::90\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'destination IPs with some ports' do
        let(:params) do
            super().merge(
              dst_ips: ['10.0.0.20', '10.0.0.10', 'fe::90', 'fe::80']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\sdaddr\s{\s10.0.0.10,\s10.0.0.20\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\sdaddr\s{\sfe::80,\sfe::90\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'both src and dst IPs with some ports' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1', 'fe::90'],
              dst_ips: ['2.0.0.2', 'fe::80']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s{\s2.0.0.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s{\sfe::80\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 only, single src' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 only, multiple src' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1', '1.0.0.2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.0.0.1,\s1.0.0.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 only, single dst' do
        let(:params) do
            super().merge(
              dst_ips: ['1.0.0.1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\sdaddr\s{\s1.0.0.1\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 only, multiple dst' do
        let(:params) do
            super().merge(
              dst_ips: ['1.0.0.1', '1.0.0.2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\sdaddr\s{\s1.0.0.1,\s1.0.0.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 only, mixed src/dst' do
        let(:params) do
            super().merge(
              src_ips: ['1.1.1.1', '1.1.1.2'],
              dst_ips: ['2.2.2.2', '2.2.2.3']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.1.1.1,\s1.1.1.2\s}\sip\sdaddr\s{\s2.2.2.2,\s2.2.2.3\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 only, single src' do
        let(:params) do
            super().merge(
              src_ips: ['fe::100']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\ssaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 only, multiple src' do
        let(:params) do
            super().merge(
              src_ips: ['fe::100']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\ssaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 only, single dst' do
        let(:params) do
            super().merge(
              dst_ips: ['fe::100']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\sdaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 only, multiple dst' do
        let(:params) do
            super().merge(
              dst_ips: ['fe::100']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\sdaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 raw src and some dst sets' do
        let(:params) do
            super().merge(
              src_ips: ['fe::90', 'fe::80'],
              dst_sets: ['dst_set1', 'dst_set2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\ssaddr\s{\sfe::80,\sfe::90\s}\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::80,\sfe::90\s}\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 raw src and some dst sets' do
        let(:params) do
            super().merge(
              src_ips: ['1.1.1.2', '1.1.1.1'],
              dst_sets: ['dst_set1', 'dst_set2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.1.1.1,\s1.1.1.2\s}\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.1.1.1,\s1.1.1.2\s}\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv6 src sets and raw dst' do
        let(:params) do
            super().merge(
              src_sets: ['src_set2', 'src_set1'],
              dst_ips: ['fe::90', 'fe::80']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv4.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s{\sfe::80,\sfe::90\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s{\sfe::80,\sfe::90\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'IPv4 src sets and raw dst' do
        let(:params) do
            super().merge(
              src_sets: ['src_set2', 'src_set1'],
              dst_ips: ['2.2.2.2', '1.1.1.1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .without_content(/ipv6.+[sd]addr/)
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s{\s1.1.1.1,\s2.2.2.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s{\s1.1.1.1,\s2.2.2.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6, source sets' do
        let(:params) do
            super().merge(
              src_sets: ['src_set2', 'src_set1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s@src_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6, dest sets' do
        let(:params) do
            super().merge(
              dst_sets: ['dst_set2', 'dst_set1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6, both sets' do
        let(:params) do
            super().merge(
              src_sets: ['src_set2', 'src_set1'],
              dst_sets: ['dst_set2', 'dst_set1']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6 with raw IPs and dst sets, with some ports' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1', 'fe::90'],
              dst_sets: ['dst_set1', 'dst_set2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6 with raw IPs and dst sets, with some ports' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1', 'fe::90'],
              dst_sets: ['dst_set1', 'dst_set2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end

      describe 'Mixed IPv4/IPv6 with all possible combinations' do
        let(:params) do
            super().merge(
              src_ips: ['1.0.0.1', 'fe::90'],
              dst_ips: ['2.2.2.2', 'fe::100'],
              src_sets: ['src_set1', 'src_set2'],
              dst_sets: ['dst_set1', 'dst_set2']
            )
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/nftables/input/10_test_service.nft')
            .with_content(/
                    #\sManaged\sby\spuppet\s+
                    #\ssome\sdesc\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set1_ipv4\sip\sdaddr\s{\s2.2.2.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s@src_set2_ipv4\sip\sdaddr\s{\s2.2.2.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set1_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s@dst_set2_ipv4\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip\ssaddr\s{\s1.0.0.1\s}\sip\sdaddr\s{\s2.2.2.2\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set1_ipv6\sip6\sdaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s@src_set2_ipv6\sip6\sdaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set1_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s@dst_set2_ipv6\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    ip6\ssaddr\s{\sfe::90\s}\sip6\sdaddr\s{\sfe::100\s}\stcp\sdport\s{\s80,\s443\s}\saccept\s+
                    /x)
        end
      end
    end
  end
end
