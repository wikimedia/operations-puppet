require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::node_cloudvirt_libvirt_stats' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) {"class { '::prometheus::node_exporter': }"}
      let(:facts) { os_facts }
      let(:params) { {} }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { should contain_file('/usr/local/bin/prometheus-node-cloudvirt-libvirt-stats') }
        it { should contain_systemd__timer__job('prometheus-node-cloudvirt-libvirt-stats') }
      end
    end
  end
end
