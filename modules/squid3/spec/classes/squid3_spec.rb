require_relative '../../../../rake_modules/spec_helper'

describe 'squid3', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      if facts[:os]['release']['major'] == '8'
        let(:squid_name) { 'squid3' }
      else
        let(:squid_name) { 'squid' }
      end

      it { is_expected.to contain_package(squid_name).with_ensure('present') }
      it { is_expected.to contain_service(squid_name).with_ensure('running') }

      it do
        is_expected.to contain_file("/etc/#{squid_name}/squid.conf").with(
          ensure: 'present',
            mode: '0444',
            owner: 'root',
            group: 'root'
        )
      end

      it do
        is_expected.to contain_file("/etc/logrotate.d/#{squid_name}").with(
          ensure: 'present',
            mode: '0444',
            owner: 'root',
            group: 'root'
        )
      end
    end
  end
end
