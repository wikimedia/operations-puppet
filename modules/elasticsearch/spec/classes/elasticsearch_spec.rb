require_relative '../../../../rake_modules/spec_helper'

describe 'elasticsearch', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'when GC logging is enabled' do
        let(:params) { {
          :apt_component => 'elastic65',
          :default_instance_params => {
            :cluster_name => 'my_cluster_name',
            :short_cluster_name => 'the_short_cluster_name',
            :gc_log => true,
            :send_logs_to_logstash => false,
            :publish_host => '127.0.0.1',
          },
        } }
        if os == '9'
          let(:facts) do
            super().merge(
              {
                :java => {
                  :version => {
                    :major => 8
                  }
                }
              })
          end
          it {
            is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/jvm.options')
                             .with_content(/-XX:\+PrintGCDetails$/)
                             .with_content(/-XX:\+PrintGCDateStamps$/)
          }
        elsif os.match?(/(10|11)/)
          let(:facts) do
            super().merge(
              {
                :java => {
                  :version => {
                    :major => 11
                  }
                }
              })
          end
          it {
            is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/jvm.options')
                             .with_content(/-Xlog:gc\+age=trace$/)
          }
        end
      end
    end
  end
end
