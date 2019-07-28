require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9', '10'],
    }
  ]
}

describe 'envoyproxy' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge({:initsystem => 'systemd'}) }
      context "On ensure present" do
        let(:params) { {:ensure => 'present', :admin_port => 8081 }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('envoyproxy') }
        it { is_expected.to contain_file('/etc/envoy').with_ensure('directory')}
      end
      context "On ensure absent" do
        let(:params) { {:ensure => 'absent', :admin_port => 8081 }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('envoyproxy').with_ensure('absent') }
        it { is_expected.to contain_file('/etc/envoy').with_ensure('absent')}
      end
    end
  end
end
