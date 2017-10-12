require 'spec_helper'

describe 'elasticsearch' do
  describe 'when NOT sending logs to logstash' do
    let(:params) { { :cluster_name  => 'my_cluster_name',
                     :publish_host  => '127.0.0.1',
    } }
    let(:facts) { { :lsbdistrelease => 'ubuntu',
                    :lsbdistid      => 'trusty'
    } }

    it { should_not contain_package('liblogstash-gelf-java') }
  end

  describe 'when sending logs to logstash' do
    let(:params) { { :cluster_name  => 'my_cluster_name',
                     :graylog_hosts => [ 'logstash.example.net', 'other' ],
                     :publish_host  => '127.0.0.1',
    } }
    let(:facts) { { :lsbdistrelease => 'ubuntu',
                    :lsbdistid      => 'trusty'
    } }

    it { should contain_package('liblogstash-gelf-java').with({ :ensure => 'present' }) }
  end
end
