# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../../rake_modules/spec_helper'

describe 'toolforge::k8s::deployer' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) {}
      let(:facts) { os_facts }
      let(:params) { {
        'toolforge_secrets' => {
          'one' => 'secret1',
        }
      } }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'it creates file with a secret' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/toolforge-deploy/secrets.yaml').with(
                ensure: 'file',
                mode: '0400'
          ).with_content(/.*one: *secret1/)
        end
      end
    end
  end
end
