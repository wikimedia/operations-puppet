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
    it { is_expected.to contain_file('/etc/default/elasticsearch')
                            .with_content(/-XX:\+PrintGCDetails -XX:\+PrintGCDateStamps/)
    }
  end

end
