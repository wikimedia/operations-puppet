require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'httpd::mpm' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { 'include ::httpd' }
      context 'without parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_httpd__mod_conf('php5')
                              .that_comes_before('Httpd::Mod_conf[mpm_worker]') }
        it { is_expected.to contain_file('/etc/apache2/mods-available/mpm_worker.load') }
        it { is_expected.to contain_httpd__mod_conf('mpm_prefork').with_ensure('absent')}
        it { is_expected.to contain_httpd__mod_conf('mpm_worker')
                              .with_ensure('present')
                              .that_notifies('Exec[apache2_test_config_and_restart]') }
      end
      context 'with mpm prefork' do
        let(:params) { {'mpm' => 'prefork'} }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_httpd__mod_conf('php5') }
      end
    end
  end
end
