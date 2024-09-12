# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::puppetserver::git' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include profile::puppetserver' }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
