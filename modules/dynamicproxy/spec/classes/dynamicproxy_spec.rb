# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'dynamicproxy' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) do
        {
          'redis_primary' => 'foo-instance.project.eqiad1.wikimedia.cloud',
        }
      end

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/nginx/sites-available/dynamicproxy') }
      end
    end
  end
end
