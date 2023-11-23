# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'interface::rule' do
  let(:title) { 'use-table-for-ip' }
  let(:pre_condition) do 'interface::routing_table { "some-table": number => 8, }' end
  let(:params) do
    { from: '192.0.2.0/24', table: 'some-table', interface: 'vlan1234' }
  end

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context 'defaults' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_interface__post_up_command('use-table-for-ip')
            .with_ensure('present')
            .with_interface('vlan1234')
            .with_command('ip rule add from 192.0.2.0/24 table some-table')
            .with_require('Interface::Routing_table[some-table]')
        end
      end

      context 'converts individual IP to a CIDR range' do
        let(:params) { super().merge(from: '192.0.2.16') }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_interface__post_up_command('use-table-for-ip')
            .with_ensure('present')
            .with_interface('vlan1234')
            .with_command('ip rule add from 192.0.2.16/32 table some-table')
            .with_require('Interface::Routing_table[some-table]')
        end
      end
    end
  end
end
