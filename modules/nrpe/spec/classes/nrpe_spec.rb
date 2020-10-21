require_relative '../../../../rake_modules/spec_helper'

describe 'nrpe' do
  on_supported_os(WMFConfig.test_on(9, 9)).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        'class profile::base { $notifications_enabled = "1"}
        include profile::base'
      end

      context "default run" do
        it { should contain_package('nagios-nrpe-server') }
        it { should contain_package('monitoring-plugins') }
        it { should contain_package('monitoring-plugins-basic') }
        it { should contain_package('monitoring-plugins-standard') }
        it { should contain_file('/etc/nagios/nrpe_local.cfg') }
        it { should contain_file('/usr/local/lib/nagios/plugins/') }
        it { should contain_service('nagios-nrpe-server') }
      end
      context "Test allowed_hosts" do
        let(:params) { { allowed_hosts: '10.10.10.10' } }

        it 'should generate valid content for nrpe_local.cfg in labs with allowed_hosts defined' do
          should contain_file('/etc/nagios/nrpe_local.cfg').with_content(/allowed_hosts=10.10.10.10/)
        end
      end
    end
  end
end
