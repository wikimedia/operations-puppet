# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'profile::lvs::interface_tweaks' do
  let(:pre_condition) { 'include base::standard_packages' }
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      context "existing interface" do
        let(:title) { 'enp4s0f0' }
        let(:facts) do
          os_facts.merge({
            'interface_primary' => 'enp4s0f0',
            'net_driver' => {
              'enp4s0f0' => {
                'driver'            => 'bnx2x',
                'duplex'            => 'full',
                'speed'             => 10_000,
                'firwmware_version' => 'FFV14.10.07 bc 7.14.11',
              },
            },
          })
        end
        it { is_expected.to compile.with_all_deps }
      end
      context "unknown interface" do
        let(:facts) { os_facts }
        let(:title) { 'enp5s0f0' }
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
