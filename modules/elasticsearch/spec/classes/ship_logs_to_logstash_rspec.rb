require 'spec_helper'

describe 'elasticsearch', :type => :class do
  describe 'when NOT sending logs to logstash' do
    let(:params) { { :cluster_name          => 'my_cluster_name',
                     :send_logs_to_logstash => false,
                     :publish_host          => '127.0.0.1',
    } }
    let(:facts) { { :lsbdistrelease => 'debian',
                    :lsbdistid      => 'jessie',
                    :initsystem     => 'systemd',
    } }

    it { should_not contain_package('liblogstash-gelf-java') }
  end

  describe 'when sending logs to logstash' do
    let(:params) { { :cluster_name          => 'my_cluster_name',
                     :logstash_host         => 'logstash.example.net',
                     :send_logs_to_logstash => true,
                     :publish_host          => '127.0.0.1',
    } }
    let(:facts) { { :lsbdistrelease => 'debian',
                    :lsbdistid      => 'jessie',
                    :initsystem     => 'systemd',
    } }

    it { should contain_package('liblogstash-gelf-java').with({ :ensure => 'present' }) }
  end
end
