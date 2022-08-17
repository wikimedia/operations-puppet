require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::node_pinger' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) {"class { '::prometheus::node_exporter': }"}
      let(:facts) { os_facts }
      let(:params) { {} }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { should contain_file('/usr/local/bin/prometheus-node-pinger') }
        it { should_not contain_systemd__timer__job('prometheus-node-pinger') }
      end

      describe 'sets systemd timer if nodes_to_ping_regular_mtu are passed' do
        let(:params) {
            super().merge({
                'nodes_to_ping_regular_mtu' => {
                  'node1' => '192.168.1.1',
                  'node2' => '192.168.1.2'
                },
            })
        }
        it { is_expected.to compile.with_all_deps }
        it { should contain_file('/usr/local/bin/prometheus-node-pinger') }
        it { should contain_systemd__timer__job('prometheus-node-pinger') }
      end

      describe 'sets systemd timer if nodes_to_ping_jumbo_mtu are passed' do
        let(:params) {
            super().merge({
                'nodes_to_ping_jumbo_mtu' => {
                  'node1' => '192.168.1.1',
                  'node2' => '192.168.1.2'
                },
            })
        }
        it { is_expected.to compile.with_all_deps }
        it { should contain_file('/usr/local/bin/prometheus-node-pinger') }
        it { should contain_systemd__timer__job('prometheus-node-pinger') }
      end

      describe 'script contains nodes for both mtu sizes' do
        let(:params) {
            super().merge({
                'nodes_to_ping_jumbo_mtu' => {
                  'node1' => '192.168.1.1',
                  'node2' => '192.168.1.2'
                },
                'nodes_to_ping_regular_mtu' => {
                  'node3' => '192.168.1.3',
                  'node4' => '192.168.1.4',
                },
            })
        }
        it { is_expected.to compile.with_all_deps }
        it {
          should contain_file('/usr/local/bin/prometheus-node-pinger')
          .with_content(/node1@192.168.1.1/)
          .with_content(/node2@192.168.1.2/)
          .with_content(/node3@192.168.1.3/)
          .with_content(/node4@192.168.1.4/)
        }
      end
    end
  end
end
