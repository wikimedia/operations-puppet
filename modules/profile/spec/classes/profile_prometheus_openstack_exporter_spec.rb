require_relative '../../../../rake_modules/spec_helper'
describe 'profile::prometheus::openstack_exporter' do
  let(:pre_condition) { }
  on_supported_os(WMFConfig.test_on(11)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { {
        'listen_port' => 4242,
        'cloud'       => 'eqiad1',
      } }
      context "compiles without errors" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('prometheus-openstack-exporter').with_ensure('running') }
        it { is_expected.to contain_file('/usr/local/sbin/prometheus-openstack-exporter-wrapper').with_ensure('file') }
      end

      context "removes everything when ensure absent" do
        let(:params) {
          super().merge(ensure: 'absent')
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('prometheus-openstack-exporter').with_ensure('stopped') }
        it { is_expected.to contain_file('/usr/local/sbin/prometheus-openstack-exporter-wrapper').with_ensure('absent') }
      end
    end
  end
end
