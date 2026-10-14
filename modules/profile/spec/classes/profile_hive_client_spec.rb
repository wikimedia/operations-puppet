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
      describe 'metastore properties' do
        let(:pre_condition) do
          "class profile::hadoop::common {}
          class bigtop::hadoop { $cluster_name = 'analytics-test-hadoop' }
          include bigtop::hadoop
          "
        end
        let(:hive_site) { '/etc/hive/conf.analytics-test-hadoop/hive-site.xml' }
        let(:params) do
          super().merge(metastore_hive_site_properties: { 'fs.s3a.endpoint' => 'rgw.example.org' })
        end
        context 'on a client' do
          it { is_expected.to contain_file(hive_site).without_content(/fs\.s3a\.endpoint/) }
        end
        context 'on the metastore host' do
          let(:params) { super().merge(deploy_jdbc_settings: true) }
          it do
            is_expected.to contain_file(hive_site)
              .with_mode('0440')
              .with_show_diff(false)
              .with_content(%r{<name>fs\.s3a\.endpoint</name>\s*<value>rgw\.example\.org</value>})
          end
        end
      end
    end
  end
end
