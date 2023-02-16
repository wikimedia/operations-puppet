# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::configmaster' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    let(:facts) { os_facts }
    let(:node_params) {{ '_role' => 'puppetmaster/frontend'  }}
    let(:pre_condition) { "include httpd" }

    context "on #{os}" do
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
