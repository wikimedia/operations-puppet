require 'spec_helper'

describe 'systemd::syslog' do
    context 'when initsystem is unknown' do
        let(:title) { 'dummyservice' }
        let(:facts) { { :initsystem => 'unknown' } }
        it { should compile.and_raise_error(/systemd::syslog is useful only with systemd/) }
    end

    context 'when initsystem is systemd' do
        let(:facts) { {:initsystem => 'systemd' } }
        let(:title) { 'dummyservice' }
        let(:pre_condition) {
            """
            base::service_unit { 'dummyservice': }
            """
        }

        describe 'when invoked with name "dummyservice"' do
            it { should compile }
            it 'should create syslog file before rsyslog configuration' do
                should contain_file('/var/log/dummyservice/syslog.log')
                    .that_comes_before('Rsyslog::Conf[dummyservice]')
            end
            it 'should configure rsyslog before the service' do
                should contain_rsyslog__conf('dummyservice')
                    .that_comes_before('Base::Service_unit[dummyservice]')
            end
            it 'should configure rsyslog to match programname dummyservice' do
                should contain_file('/etc/rsyslog.d/20-dummyservice.conf')
                    .with_content(%r%^:programname, startswith, "dummyservice" /var/log/dummyservice/syslog\.log$%)
            end
        end

        describe 'when invoked with base_dir=/srv/log' do
            let(:params) { {
                :base_dir => '/srv/log',
            } }
            it {
                should contain_file('/srv/log/dummyservice')
                    .with_ensure('directory')
            }
            it {
                should contain_file('/srv/log/dummyservice/syslog.log')
            }
            it "should logrotates /srv/log/dummyservice/*.log" do
                should contain_file('/etc/logrotate.d/dummyservice')
                    .with_content(%r%^/srv/log/dummyservice/\*\.log {$%)
            end
        end

        describe 'when invoked with log_filename=instance01.log' do
            let(:params) { {
                :log_filename => 'instance01.log'
            } }
            it 'should configure rsyslog to log to instance01.log' do
                should contain_file('/etc/rsyslog.d/20-dummyservice.conf')
                    .with_content(%r%^:programname, .* /var/log/dummyservice/instance01\.log$%)
            end
        end
    end
end
