# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'elasticsearch', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'when new ratio is enabled' do
        let(:params) { {
          :apt_component => 'elastic65',
          :default_instance_params => {
            :cluster_name => 'my_cluster_name',
            :short_cluster_name => 'the_short_cluster_name',
            :send_logs_to_logstash => false,
            :publish_host => '127.0.0.1',
            :tune_gc_new_size_ratio => 2,
          },
        } }
        it {
          is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/jvm.options')
                             .with_content(/-XX:NewRatio=2/)
        }
      end

      describe 'when new ratio is disabled' do
        let(:params) { {
          :apt_component => 'elastic65',
          :default_instance_params => {
            :cluster_name => 'my_cluster_name',
            :short_cluster_name => 'the_short_cluster_name',
            :send_logs_to_logstash => false,
            :publish_host => '127.0.0.1',
          },
        } }
        it {
          is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/jvm.options')
                             .without_content(/NewRatio/)
        }
      end
    end
  end
end
