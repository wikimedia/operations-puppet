require_relative '../../../../rake_modules/spec_helper'

describe 'profile::doc' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # For Exec[apt-get update] needed by apt::repository
      let(:pre_condition) { "include apt"}
      it { is_expected.to compile }
      it { is_expected.to contain_package('php8.2-fpm') }
      it "provides a fpm restart script" do
        is_expected.to contain_file('/usr/local/sbin/restart-php-fpm-unsafe')
          .with_content(%r{-- /bin/systemctl restart php8.2-fpm$})
      end
      it "limits PHP-FPM and restarts it on change" do
        is_expected.to contain_file('php-restrictions-confd')
          .with_path('/etc/php/8.2/fpm/conf.d/50-restrictions.ini')
          .with_content(%r{^open_basedir = /srv/deployment/integration/:/srv/doc/$})
          .with_content(/^disable_functions = .*\bproc_open\b/)
          .with_content(%r{^sendmail_path = /bin/false$})
          .that_notifies('Exec[php-fpm-restart]')
      end
    end
  end
end
