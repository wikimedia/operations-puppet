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
end
