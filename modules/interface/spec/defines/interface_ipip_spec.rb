# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'interface::ipip' do
  let(:title) { 'some-command' }
  let(:params) do
    { 'ensure' => 'present', 'interface' => 'ipip0', 'family' => 'inet', 'address' => '127.0.0.42' }
  end

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "defaults" do
        it { is_expected.to compile.with_all_deps }
      end

      context "when absented" do
        let(:params) { super().merge('ensure' => 'absent') }
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
