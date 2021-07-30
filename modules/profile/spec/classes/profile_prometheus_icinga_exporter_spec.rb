require_relative '../../../../rake_modules/spec_helper'
describe 'profile::prometheus::icinga_exporter' do
  let(:pre_condition) { }
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { {
        'prometheus_nodes' => ['prometheus01', 'prometheus02'],
        'active_host'      => 'prometheus01',
        'partners'         => ['prometheus02'],
        'alertmanagers'    => ['am01', 'am02'],
      } }
      context "compiles without errors" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
