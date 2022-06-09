# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'external_clouds_vendors' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe "Test with default parameters" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
