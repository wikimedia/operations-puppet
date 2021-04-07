require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::syslog' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:title) { 'dummyservice' }
      let(:facts) { os_facts }

      context 'when a service is defined' do
        let(:pre_condition) { 'service { "dummyservice": ensure => running, provider => "systemd"}' }
        it 'should create syslog file before rsyslog configuration' do
          is_expected.to contain_file('/var/log/dummyservice/syslog.log')
                  .that_comes_before('Rsyslog::Conf[dummyservice]')
        end
        it 'should configure rsyslog before the service' do
          is_expected.to contain_rsyslog__conf('dummyservice')
                  .that_comes_before('Service[dummyservice]')
        end
        it 'should configure rsyslog to match programname dummyservice' do
          is_expected.to contain_file('/etc/rsyslog.d/20-dummyservice.conf')
                  .with_content(%r%^:programname, startswith, "dummyservice" /var/log/dummyservice/syslog\.log$%)
        end
      end

      context 'when invoked with base_dir=/srv/log' do
        let(:params) { { base_dir: '/srv/log', } }
        it { is_expected.to contain_file('/srv/log/dummyservice').with_ensure('directory') }
        it { is_expected.to contain_file('/srv/log/dummyservice/syslog.log') }
        it "should logrotates /srv/log/dummyservice/*.log" do
          is_expected.to contain_file('/etc/logrotate.d/dummyservice')
                  .with_content(%r%^/srv/log/dummyservice/\*\.log {$%)
        end
      end

      context 'when invoked with log_filename=instance01.log' do
        let(:params) { {log_filename: 'instance01.log'} }
        it 'should configure rsyslog to log to instance01.log' do
          is_expected.to contain_file('/etc/rsyslog.d/20-dummyservice.conf')
                  .with_content(%r%^:programname, .* /var/log/dummyservice/instance01\.log$%)
        end
      end
    end
  end
end
