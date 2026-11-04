# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::trafficserver::backend' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    ['cache/text', 'cache/upload'].each do |cluster|
      context "on #{os} (#{cluster})" do
        let(:facts) { os_facts }
        let(:node_params) {{ '_role' => cluster }}

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
