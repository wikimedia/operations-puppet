require 'spec_helper'

describe 'elasticsearch::https', :type => :class do
  let(:facts) { { :lsbdistrelease => 'ubuntu',
                  :lsbdistid      => 'trusty',
                  :fqdn => 'host.example.net'
  } }

  context 'with default parameters' do
    it 'should ensure that certificates are present' do
      should contain_file('/etc/nginx/ssl/cert.pem').with({ 'ensure' => 'present' })
      should contain_file('/etc/nginx/ssl/server.key').with({ 'ensure' => 'present' })
    end

    it 'should ensure that nginx package is present' do
      should contain_package('nginx-full').with({ 'ensure' => 'present' })
    end
  end

  context 'with ensure => absent' do
    let(:params) { { :ensure => 'absent' } }

    it 'should ensure that certificates are absent' do
      should contain_file('/etc/nginx/ssl/cert.pem').with({ 'ensure' => 'absent' })
      should contain_file('/etc/nginx/ssl/server.key').with({ 'ensure' => 'absent' })
    end

    it 'should ensure that nginx package is absent' do
      should contain_package('nginx-full').with({ 'ensure' => 'absent' })
    end
  end

end
