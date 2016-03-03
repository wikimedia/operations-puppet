require 'spec_helper'

describe 'elasticsearch::https', :type => :class do
  let(:facts) { { :lsbdistrelease => 'ubuntu',
                  :lsbdistid      => 'trusty',
                  :fqdn => 'host.example.net'
  } }

  describe 'certificates are absent by default' do
    it { should contain_file('/etc/nginx/ssl/cert.pem').with({ 'ensure' => 'absent' }) }
    it { should contain_file('/etc/nginx/ssl/server.key').with({ 'ensure' => 'absent' }) }
  end

  describe 'When enabled, nginx is installed and certificates are available' do
    let(:params) { { :ensure => 'present' } }

    it { should contain_package('nginx-full') }
    it { should contain_file('/etc/nginx/ssl/cert.pem').with({ 'ensure' => 'present' }) }
    it { should contain_file('/etc/nginx/ssl/server.key').with({ 'ensure' => 'present' }) }
  end

end
