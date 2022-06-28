# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
describe "profile::toolforge::grid::exec_environ" do
  # We olny support buster for now (buster -> 10, bullseye -> 11)
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { {} }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
