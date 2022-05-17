# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'bgpalerter' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
