require 'spec_helper'

describe 'elasticsearch', :type => :class do
  let(:facts) { { :lsbdistrelease => 'ubuntu',
                  :lsbdistid      => 'trusty'
  } }

  describe 'when multicast enabled' do
    let(:params) { {
        :cluster_name      => 'my_cluster_name',
        :multicast_enabled => true,
    } }
    it { is_expected.to contain_file('/etc/elasticsearch/elasticsearch.yml')
                            .with_content(/^#discovery\.zen\.ping\.multicast\.enabled: false$/)
                            .without_content(/^discovery\.zen\.ping\.multicast\.enabled: false$/)
    }
  end

  describe 'when multicast disabled' do
    let(:params) { {
        :cluster_name      => 'my_cluster_name',
        :multicast_enabled => false,
    } }
    it { is_expected.to contain_file('/etc/elasticsearch/elasticsearch.yml')
                            .with_content(/^discovery\.zen\.ping\.multicast\.enabled: false$/)
                            .without_content(/^#discovery\.zen\.ping\.multicast\.enabled: false$/)
    }
  end

end
