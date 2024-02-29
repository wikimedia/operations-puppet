# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'tomcat' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, _facts|
    context "on #{os}" do
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
