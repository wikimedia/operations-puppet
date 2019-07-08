require 'spec_helper'

describe 'nginx', :type => :class do
  let(:facts) {{
      :lsbdistrelease => 'ubuntu',
      :lsbdistid      => 'trusty'
  }}

  context 'with ensure => present' do
    let(:params) { { :ensure => 'present' } }

    it 'should install nginx packages' do
      should contain_package('nginx-common').with({'ensure' => 'present'})
      should contain_package('nginx-full').with({'ensure' => 'present'})
    end

    it 'should ensure that nginx service is started and enabled' do
      should contain_service('nginx').with({'ensure' => 'running', 'enable' => true})
    end

    it 'should ensure that nginx configuration directories exist' do
      should contain_file('/etc/nginx/conf.d').with({'ensure' => 'directory'})
      should contain_file('/etc/nginx/sites-available').with({'ensure' => 'directory'})
      should contain_file('/etc/nginx/sites-enabled').with({'ensure' => 'directory'})
    end
  end

  context 'with ensure => absent' do
    let(:params) { { :ensure => 'absent' } }

    it 'should remove nginx packages' do
      should contain_package('nginx-common').with({'ensure' => 'absent'})
      should contain_package('nginx-full').with({'ensure' => 'absent'})
    end

    it 'should ensure that nginx service is stopped and disabled' do
      should contain_service('nginx').with({'ensure' => 'stopped', 'enable' => false})
    end

    it 'should ensure that nginx configuration directories are removed' do
      should contain_file('/etc/nginx/conf.d').with({'ensure' => 'absent'})
      should contain_file('/etc/nginx/sites-available').with({'ensure' => 'absent'})
      should contain_file('/etc/nginx/sites-enabled').with({'ensure' => 'absent'})
    end
  end
end
