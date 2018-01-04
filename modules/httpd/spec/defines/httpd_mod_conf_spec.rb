require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'httpd::mod_conf' do
  let(:pre_condition){ 'service { "apache2": ensure => running }'}
  let(:title) { 'foobar' }
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      context 'with parameters defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('ensure_present_mod_foobar')
                              .with_command('/usr/sbin/a2enmod foobar')
                              .with_creates('/etc/apache2/mods-enabled/foobar.load')
                              .that_notifies('Service[apache2]')}
      end
      context 'with ensure absent' do
        let(:params){ {'ensure' => 'absent'} }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('ensure_absent_mod_foobar')
                              .with_command('/usr/sbin/a2dismod -f foobar')
                              .with_onlyif('/usr/bin/test -L /etc/apache2/mods-enabled/foobar.load')
                              .that_notifies('Service[apache2]')}
      end
    end
  end
end
