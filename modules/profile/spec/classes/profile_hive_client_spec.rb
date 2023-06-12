# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::hive::client' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) do
        "class profile::hadoop::common {}
        class bigtop::hadoop {}
        include bigtop::hadoop
        "
      end
      let(:facts) { os_facts }
      let(:params) do
        {
          hive_service_name: 'analytics-test-hive',
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/beeline.ini')
            .with_content(
              %r{jdbc=jdbc:hive2://analytics-test-hive.eqiad.wmnet:10000/default;principal=hive/analytics-test-hive.eqiad.wmnet@WIKIMEDIA})
        end
      end
    end
  end
end
