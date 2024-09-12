# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::puppetserver::volatile' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          'networking' => os_facts[:networking].merge({'fqdn' => 'puppetserver1001.eqiad.wmnet'})
        })
      end
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
      let(:node_params) {{ '_role' => 'puppetserver' }}
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
