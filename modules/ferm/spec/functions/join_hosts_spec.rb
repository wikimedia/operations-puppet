# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'ferm::join_hosts' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        "function dnsquery::lookup($name, $force_ipv6) {
           case $name {
             'example.org': { ['192.0.2.11', '2001:db8::11'] }
             'example.com': { ['192.0.2.12', '192.0.2.13'] }
             default:       { ['192.0.2.255'] }
           }
        }"
      end

      it { is_expected.to run.with_params('192.0.2.1').and_return('192.0.2.1') }
      it { is_expected.to run.with_params('@resolve((example.org))').and_return('@resolve((example.org))') }
      it { is_expected.to run.with_params('$DOMAIN_NETWORKS').and_return('$DOMAIN_NETWORKS') }

      it { is_expected.to run.with_params(['192.0.2.1']).and_return('(192.0.2.1)') }
      it { is_expected.to run.with_params(['192.0.2.0/24']).and_return('(192.0.2.0/24)') }
      it { is_expected.to run.with_params(['192.0.2.2', '192.0.2.1']).and_return('(192.0.2.1 192.0.2.2)') }

      it { is_expected.to run.with_params(['$VARIABLE1']).and_return('($VARIABLE1)') }

      it { is_expected.to run.with_params(['example.org']).and_return('(192.0.2.11 2001:db8::11)') }
      it { is_expected.to run.with_params(['example.org', 'example.com']).and_return('(192.0.2.11 192.0.2.12 192.0.2.13 2001:db8::11)') }

      it do
        is_expected.to run.with_params(['192.0.2.1', 'example.org', '$EXAMPLE_VARIABLE'])
          .and_return('($EXAMPLE_VARIABLE 192.0.2.1 192.0.2.11 2001:db8::11)')
      end
    end
  end
end
