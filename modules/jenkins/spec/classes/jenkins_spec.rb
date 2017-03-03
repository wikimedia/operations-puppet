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
        it 'should expose JENKINS_HOME in environment' do
            # Required by Jenkins
            should contain_file('/lib/systemd/system/jenkins.service')
                .with_content(%r%^Environment=JENKINS_HOME=/var/lib/jenkins$%)
        end
        it 'should pass prefix to jenkins' do
            should contain_file('/lib/systemd/system/jenkins.service')
                .with_content(%r% --prefix=/ci$%)
        end
        context 'when http port is given' do
            let(:params) { {
                :prefix => '/ci',
                :http_port => 8042,
            } }
            it 'should set http port' do
                should contain_file('/lib/systemd/system/jenkins.service')
                    .with_content(/ --httpPort=8042 /)
            end
        end
        context 'when access log is enabled' do
            let(:params) { {
                :prefix => '/ci',
                :access_log => true,
            } }
            it 'should set Jenkins access logger' do
                should contain_file('/lib/systemd/system/jenkins.service')
                    .with_content(/SimpleAccessLogger.+\\$/)
            end
        end
    end
end
