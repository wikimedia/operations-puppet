# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'squid', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      it { is_expected.to contain_package('squid').with_ensure('present') }
      it { is_expected.to contain_service('squid').with_ensure('running') }

      it do
        is_expected.to contain_file("/etc/squid/squid.conf").with(
          ensure: 'present',
            mode: '0444',
            owner: 'root',
            group: 'root'
        )
      end

      it do
        is_expected.to contain_file("/etc/logrotate.d/squid").with(
          ensure: 'present',
            mode: '0444',
            owner: 'root',
            group: 'root'
        )
      end
    end
  end
end
