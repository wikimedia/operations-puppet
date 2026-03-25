# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'tofurkey' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:params) do
        {
          enabled: true,
          keyfile: 'keyfile',
          rotation_interval: 604_800
        }
      end
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_package('tofurkey') }
      it { is_expected.to contain_file('/etc/tofurkey').with_ensure('directory') }
      # it { is_expected.to contain_file('/etc/tofurkey/secret').with_content('0123456789abcdefghijklmnopqrstuv') }
    end
  end
end
