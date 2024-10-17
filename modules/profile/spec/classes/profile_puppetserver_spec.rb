# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::puppetserver' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<~EOF
        function wmflib::class::hosts($name, $loc = []) {
          $name ? {
            'puppetserver::ca' => ['puppetserver2001.codfw.wmnet'],
            default => [],
          }
        }
        EOF
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      context "on #{os} using puppetserver role (ca host)" do
        let(:facts) do
          os_facts.merge({
              'hostname' => 'puppetserver1001',
          })
        end
        let(:node_params) {{ _role: 'puppetserver' }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetserver::ca').with_intermediate_ca(true) }
      end
      context "on #{os} using puppetserver role (not ca host)" do
        let(:facts) do
          os_facts.merge({
              'hostname' => 'puppetserver2001',
          })
        end
        let(:node_params) {{ _role: 'puppetserver' }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('puppetserver::ca').with_intermediate_ca(false) }
      end
    end
  end
end
