require_relative '../../../../rake_modules/spec_helper'

describe 'profile::doc' do
  on_supported_os(WMFConfig.test_on(10, 11)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # For Exec[apt-get update] needed by apt::repository
      let(:pre_condition) { "include apt"}
      it { is_expected.to compile }
      it { is_expected.to contain_package('php7.4-fpm') }
      it "provides a fpm restart script" do
        is_expected.to contain_file('/usr/local/sbin/restart-php-fpm-unsafe')
          .with_content(%r{-- /bin/systemctl restart php7.4-fpm$})
      end
    end
  end
end
