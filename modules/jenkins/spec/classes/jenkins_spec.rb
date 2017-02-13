require 'spec_helper'

describe 'jenkins' do
    let(:facts) { {
        :initsystem => 'systemd',  # For systemd::syslog
    } }
    let(:params) { {
        :prefix => '/ci',
    } }
    it { should compile }

    describe 'when service_ensure' do
        context "is 'unmanaged'" do
            let(:params) { {
                :prefix => '/ci',
                :service_ensure => 'unmanaged',
            } }
            it { should contain_service('jenkins').without_ensure }
        end
        context "is 'running'" do
            let(:params) { {
                :prefix => '/ci',
                :service_ensure => 'running',
            } }
            it { should contain_service('jenkins') .with_ensure('running') }
        end
        context "is 'stopped'" do
            let(:params) { {
                :prefix => '/ci',
                :service_ensure => 'stopped',
            } }
            it { should contain_service('jenkins') .with_ensure('stopped') }
        end
    end
    describe 'systemd jenkins service' do
        it 'should set Umask' do
            should contain_file('/lib/systemd/system/jenkins.service')
                .with_content(/^UMask=0002$/)
        end
        it 'should set LimitNOFILE' do
            should contain_file('/lib/systemd/system/jenkins.service')
                .with_content(/^LimitNOFILE=8192$/)
        end
        it 'should have Environment directives set' do
            should contain_file('/lib/systemd/system/jenkins.service')
                .with_content(/^Environment="JENKINS_JAVA_ARGS=[^"]+"$/)
                .with_content(/^Environment=JENKINS_HTTP_PORT=8080$/)
                .with_content(%r%^Environment=JENKINS_PREFIX=/ci$%)
        end
        context 'when access log is enabled' do
            let(:params) { {
                :prefix => '/ci',
                :access_log => true,
            } }
            it 'should set Jenkins access logger' do
                should contain_file('/lib/systemd/system/jenkins.service')
                    .with_content(/^Environment="JENKINS_JAVA_ARGS=[^"]+SimpleAccessLogger[^"]*"$/)
            end
        end
    end
    describe 'rsyslog configuration' do
        it 'should match programname with a strict equality' do
            should contain_file('/etc/rsyslog.d/20-jenkins.conf')
                .with_content(/^:programname, isequal, "jenkins"/)
        end
    end
end
