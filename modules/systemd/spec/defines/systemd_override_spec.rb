# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::override' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:title) { 'dummyoverride' }
      let(:facts) { os_facts }
      let(:params) do
        {
          content: 'dummy',
          unit: 'dummyservice'
        }
      end

      it { is_expected.to compile }
      it do
        is_expected.to contain_systemd__unit('dummyservice-dummyoverride')
          .with(
            ensure: 'present',
            unit: 'dummyservice',
            content: 'dummy',
            restart: false
          )
      end
    end
  end
end
