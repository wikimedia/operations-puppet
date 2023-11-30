# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::installserver::preseed' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:node_params) { {
        # Specifying the _role will allow the test to rely on the actual
        # hieradata/role/common/apt_repo.yaml data.
        # If any typo is introduced in the data, the test will fail, allowing
        # the author to detect the typo before it hits production.
        '_role' => 'apt_repo',
      }}
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
