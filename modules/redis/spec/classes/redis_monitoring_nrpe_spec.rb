# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "redis::monitoring::nrpe" do
  on_supported_os(WMFConfig.test_on(10)).each do |os|
    context "On #{os}" do
      describe "compiles without errors" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
