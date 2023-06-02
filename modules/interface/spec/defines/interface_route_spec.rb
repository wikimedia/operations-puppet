# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'interface::route' do
  let(:title) { 'dummyroute' }
  let(:params) {{
     'address' => '10.10.10.10',
     'nexthop' => '10.0.0.1',
  }}

  on_supported_os(WMFConfig.test_on).each do |os|
    context "on #{os}" do
      context "defaults" do
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_exec('ip route add 10.10.10.10/32 via 10.0.0.1   ')
            should_not contain_interface__post_up_command('dummyroute_persist')
          }
      end
      context "when persisting" do
          let(:params) { super().merge(
            'interface' => 'eth0',
            'persist' => true
          )}
          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_exec('ip route add 10.10.10.10/32 via 10.0.0.1   dev eth0')
            is_expected.to contain_interface__post_up_command('dummyroute_persist').with(
                'interface' => 'eth0',
                'command' => 'ip route add 10.10.10.10/32 via 10.0.0.1   dev eth0'
            )
          }
      end
      context "when persisting but missing interface" do
          let(:params) { super().merge(
            'persist' => true
          )}
          it {
            is_expected.to compile.and_raise_error(/interface::route: missing target interface to persist/)
          }
      end
    end
  end
end
