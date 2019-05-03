require 'spec_helper'

describe 'elasticsearch', :type => :class do
  let(:facts) { { :lsbdistrelease => 'debian',
                  :lsbdistid      => 'jessie',
                  :initsystem     => 'systemd',
  } }

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
        is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/jvm.options')
            .with_content(/-XX:\+PrintGCDetails$/)
            .with_content(/-XX:\+PrintGCDateStamps$/)
    }
  end
end
