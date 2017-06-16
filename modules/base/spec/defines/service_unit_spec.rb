require 'spec_helper'

describe 'base::service_unit' do
  let(:title) { 'nginx' }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }
    context 'with a systemd unit file' do
      let(:params) { { :ensure => 'present', :systemd => 'test'}}

      it 'should activate the service' do
        should contain_service('nginx')
      end

      it 'should install a service file' do
        should contain_file('/lib/systemd/system/nginx.service')
                 .with_content('test')
      end

      it 'should execute daemon-reload' do
        should contain_exec('systemd reload for nginx')
                   .that_comes_before('Service[nginx]')
                   .that_subscribes_to('File[/lib/systemd/system/nginx.service]')
      end
    end

    context 'without a unit file' do
      let(:params) { { :ensure => 'present', :sysvinit => 'test'}}
      it 'should install an init script' do
        should contain_file('/etc/init.d/nginx').with_content('test')
      end

      it 'should execute daemon-reload' do
        should contain_file('/etc/init.d/nginx').that_notifies('Exec[systemd reload for nginx]').that_notifies('Service[nginx]')
        should contain_exec('systemd reload for nginx').that_comes_before('Service[nginx]')
      end
    end
  end
  context 'with refresh false' do
    let(:facts) { {:initsystem => 'sysvinit'} }
    let(:params) { { :ensure => 'present', :sysvinit => 'test', :refresh => false}}

    it 'should not refresh service' do
      expect {
        should contain_file('/etc/init.d/nginx').that_notifies('Service[nginx]')
      }.to raise_error()
    end
  end

  context 'with refresh true' do
    let(:facts) { {:initsystem => 'sysvinit'} }
    let(:params) { { :ensure => 'present', :sysvinit => 'test', :refresh => true}}

    it 'should refresh service' do
        should contain_file('/etc/init.d/nginx').that_notifies('Service[nginx]')
    end
  end
  context 'with upstart as init' do
    let(:facts) { {:initsystem => 'upstart'} }
    context 'with an upstart conf file' do
      let(:params) { { :ensure => 'present', :upstart => 'test'}}
      it 'should activate the service' do
        should contain_service('nginx')
      end

      it 'should install a service file' do
        should contain_file('/etc/init/nginx.conf')
      end

      it 'should notify service' do
        should contain_file('/etc/init/nginx.conf').that_notifies('Service[nginx]')
      end
    end

    context 'without a unit file' do
      let(:params) { { :ensure => 'present', :sysvinit => 'test'}}
      it 'should install an init script' do
        should contain_file('/etc/init.d/nginx')
      end

      it 'should notify service' do
        should contain_file('/etc/init.d/nginx')
                 .with_content('test')
                 .that_notifies('Service[nginx]')
      end
    end

    # MARK
  end
end
