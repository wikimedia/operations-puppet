# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
describe 'profile::gerrit::proxy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          'ipv4' => '198.51.100.1',
          'ipv6' => '2001:DB8::CAFE',
          'host' => 'gerrit.example.org',
          'daemon_user' => 'gerrit2',
          'is_replica' => false,
          'use_acmechief' => true,
          'enable_monitoring' => true,
          'replica_hosts' => ['gerrit-replica.example.org'],
        }
      }

      it { is_expected.to compile.with_all_deps }
    end
  end
end
