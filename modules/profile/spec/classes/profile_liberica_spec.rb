# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::liberica' do
  let(:pre_condition) do
    [
      'class { "::prometheus::node_exporter": }',
    ]
  end
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
        let(:facts) do
          os_facts.merge({
            'hostname'    => 'lvs1013',
            'site'        => 'eqiad',
            'interface_primary' => 'enp4s0f0',
            'default_routes' => {
              'ipv4' => '10.0.0.1',
            },
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
  end
end
