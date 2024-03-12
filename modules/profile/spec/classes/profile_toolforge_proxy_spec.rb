# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
describe "profile::toolforge::proxy" do
  on_supported_os(WMFConfig.test_on(10, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { {} }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
