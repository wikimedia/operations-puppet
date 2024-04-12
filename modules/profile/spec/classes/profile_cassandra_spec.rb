# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::cassandra' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      # We need to set the hostname to find the correct secret
      let(:facts) { os_facts.merge(hostname: 'sessionstore1004-a') }
      let(:params) {{ rack: 'A3' }}
      let(:node_params) {{ '_role' => 'sessionstore' }}
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
