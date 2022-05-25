# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'opensearch', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'when GC logging is enabled' do
        let(:params) { {
          :default_instance_params => {
            :cluster_name => 'my_cluster_name',
            :short_cluster_name => 'the_short_cluster_name',
            :gc_log => true,
            :send_logs_to_logstash => false,
            :publish_host => '127.0.0.1',
          },
        } }
        it {
          is_expected.to contain_file('/etc/opensearch/my_cluster_name/jvm.options')
            .with_content(/-XX:\+PrintGCDetails$/)
            .with_content(/-XX:\+PrintGCDateStamps$/)
        }
      end
    end
  end
end
