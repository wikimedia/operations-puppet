require 'spec_helper'

describe 'elasticsearch', :type => :class do
  let(:facts) { { :lsbdistrelease => 'ubuntu',
                  :lsbdistid      => 'trusty'
  } }

  describe 'when GC logging is enabled' do
    let(:params) { {
        :cluster_name => 'my_cluster_name',
        :gc_log       => true,
    } }
    it {
        is_expected.to contain_file('/etc/elasticsearch/jvm.options')
            .with_content(/-XX:\+PrintGCDetails$/)
            .with_content(/-XX:\+PrintGCDateStamps$/)
    }
  end

end
