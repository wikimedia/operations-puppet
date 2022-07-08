# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'nginx', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      case facts[:os]['distro']['codename']
      when 'bookworm'
        let(:nginx_deb) { 'nginx' }
      else
        let(:nginx_deb) { 'nginx-full' }
      end

      context 'with ensure => present' do
        let(:params) { { :ensure => 'present' } }

        it 'should install nginx packages' do
          should contain_package(nginx_deb).with({'ensure' => 'installed'})
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
          should contain_package(nginx_deb).with({'ensure' => 'absent'})
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
  end
end
