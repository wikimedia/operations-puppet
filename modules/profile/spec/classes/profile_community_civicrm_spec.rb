# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::community_civicrm' do
  on_supported_os(WMFConfig.test_on(11)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          config_nonce: 'random',
          git_branch: 'main',
          hash_salt: 'salt',
          db_pass: 'supper_safe',
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
