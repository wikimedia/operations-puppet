require 'spec_helper'

describe 'icinga::monitor::elasticsearch::cirrus_settings_check', :type => :define do
  let(:facts) { { :lsbdistrelease => 'debian',
                  :lsbdistid      => 'jessie',
                  :initsystem     => 'systemd',
  } }

  describe 'when remote search is disabled' do
      let(:title) { 'my_cluster_name' }
      let(:params) { {
        :port => 9201,
        :settings => {'my_cluster_name' => {
                'cluster_name'          => 'my_cluster_name',
                'short_cluster_name'    => 'the_short_cluster_name',
                'send_logs_to_logstash' => true,
                'publish_host'          => '127.0.0.1',
            }},
        :enable_remote_search => false,
      } }

      it { is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/cirrus_check_settings.yaml').with_content(/^\n$/)}
  end

  describe 'when remote search is enabled' do
      let(:title) { 'my_cluster_name' }
      let(:params) { {
        :port => 9201,
        :settings => {
            'my_gamma_cluster' => {
                'cluster_name'          => 'my_gamma_cluster_name',
                'short_cluster_name'    => 'gamma',
                'send_logs_to_logstash' => true,
                'publish_host'          => '127.0.0.1',
                'unicast_hosts'         => ['host1', 'host2'],
                'transport_tcp_port'    => 9900,
            },
            'my_cluster_name' => {
                'cluster_name'          => 'my_cluster_name',
                'short_cluster_name'    => 'phi',
                'send_logs_to_logstash' => true,
                'publish_host'          => '127.0.0.1',
                'unicast_hosts'         => ['host5', 'host4'],
                'transport_tcp_port'    => 9700,
            },
        },
        :enable_remote_search => true,
      } }

      it { is_expected.to contain_file('/etc/elasticsearch/my_cluster_name/cirrus_check_settings.yaml')
            .with_content(<<~EOM
            - "$.search.remote.gamma.seeds":
              - host1:9900
              - host2:9900

           EOM
            )
      }
  end
end
