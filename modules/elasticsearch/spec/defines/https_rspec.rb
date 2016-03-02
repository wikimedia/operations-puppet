require 'spec_helper'

describe 'elasticsearch::https', :type => :class do

  describe 'haproxy and certificates are absent by default' do
    let(:facts) { { :fqdn => 'host.example.net'} }

    it { should contain_package('haproxy').with({ 'ensure' => 'absent' }) }
    it { should contain_file('/etc/haproxy/haproxy.cfg').with({ 'ensure' => 'absent' }) }
    it { should contain_file('/etc/haproxy/ssl/certs/cert.pem').with({ 'ensure' => 'absent' }) }
  end

  describe 'When enabled, haproxy is installed and certificates are available' do
    let(:facts) { { :fqdn => 'host.example.net'} }
    let(:params) { { 'ensure' => 'present' } }

    it { should contain_package('haproxy').with({ 'ensure' => 'present' }) }
    it { should contain_file('/etc/haproxy/haproxy.cfg').with({ 'ensure' => 'present' }) }
    it { should contain_file('/etc/haproxy/ssl/certs/cert.pem').with({ 'ensure' => 'present' }) }
  end

end
