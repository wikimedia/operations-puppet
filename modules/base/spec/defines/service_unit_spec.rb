require 'spec_helper'

describe 'base::service_unit' do
  let(:title) { 'nginx' }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }
    context 'with a systemd unit file' do
      let(:params) { { :ensure => 'present', :systemd => true}}

      it 'should activate the service' do
        should contain_service('nginx')
      end

      it 'should install a service file' do
        should contain_file('/etc/systemd/system/nginx.service')
      end

      it 'should execute daemon-reload' do
        should contain_file('/etc/systemd/system/nginx.service').that_notifies('Exec[systemd reload for nginx]')
        should contain_exec('Exec[systemd reload for nginx]').that_comes_before('Service[nginx]')
      end
    end

    context 'without a unit file' do
      let(:params) { { :ensure => 'present', :sysvinit => true}}
      it 'should install an init script' do
        should contain_file('/etc/init.d/nginx')
      end

      it 'should execute daemon-reload' do
        should contain_file('/etc/init.d/nginx').that_notifies('Exec[systemd reload for nginx]')
        should contain_exec('Exec[systemd reload for nginx]').that_comes_before('Service[nginx]')
      end

    end
  end

  context 'with upstart as init' do
    #MARK
  end
end
