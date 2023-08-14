# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::puppetserver::volatile' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node_params) {{ '_role' => 'puppetserver' }}
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
