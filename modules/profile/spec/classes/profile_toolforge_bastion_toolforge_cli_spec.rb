# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
describe 'profile::toolforge::bastion::toolforge_cli' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge({
          'wmcs_project' => 'dummyproject',
      }) }
      let(:params) { {} }

      context 'compiles by itself' do
          it { is_expected.to compile.with_all_deps }
      end

      context 'when on tools the toolforge config has the tools harbor' do
          let(:facts) { super().merge({
              'wmcs_project' => 'tools',
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/toolforge/common.yaml').with_content(/.*tools-harbor.*/) }
      end

      context 'when on toolsbeta the toolforge config has the toolsbeta harbor' do
          let(:facts) { super().merge({
              'wmcs_project' => 'toolsbeta',
          }) }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/toolforge/common.yaml').with_content(/.*toolsbeta-harbor.*/) }
      end
    end
  end
end
