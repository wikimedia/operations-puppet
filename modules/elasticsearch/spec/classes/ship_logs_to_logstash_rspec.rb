require 'spec_helper'

describe 'elasticsearch', :type => :class do
  describe 'when NOT sending logs to logstash' do
    let(:params) { {
        :default_instance_params => {
            :cluster_name          => 'my_cluster_name',
            :short_cluster_name    => 'the_short_cluster_name',
            :send_logs_to_logstash => false,
            :publish_host          => '127.0.0.1',
        }
    } }
    let(:facts) { { :lsbdistrelease => 'debian',
                    :lsbdistid      => 'jessie',
                    :initsystem     => 'systemd',
    } }

    it { should_not contain_package('liblogstash-gelf-java') }
  end

  describe 'when sending logs to logstash' do
    let(:params) { {
        :logstash_host => 'logstash.example.net',
        :default_instance_params => {
            :cluster_name          => 'my_cluster_name',
            :short_cluster_name    => 'the_short_cluster_name',
            :send_logs_to_logstash => true,
            :publish_host          => '127.0.0.1',
        }
    } }
    let(:facts) { { :lsbdistrelease => 'debian',
                    :lsbdistid      => 'jessie',
                    :initsystem     => 'systemd',
    } }

    it { should contain_package('liblogstash-gelf-java').with({ :ensure => 'present' }) }
  end
end
