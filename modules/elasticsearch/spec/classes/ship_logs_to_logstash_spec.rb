require_relative '../../../../rake_modules/spec_helper'

describe 'elasticsearch', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'when NOT sending logs to logstash' do
        let(:params) { {
          :apt_component => 'elastic65',
          :java_vers => 11,
          :default_instance_params => {
            :cluster_name          => 'my_cluster_name',
            :short_cluster_name    => 'the_short_cluster_name',
            :send_logs_to_logstash => false,
            :publish_host          => '127.0.0.1',
          }
        } }

        it { should_not contain_package('liblogstash-gelf-java') }
      end

      describe 'when sending logs to logstash' do
        let(:params) { {
          :apt_component => 'elastic65',
          :java_vers => 11,
          :logstash_host => 'logstash.example.net',
          :default_instance_params => {
            :cluster_name          => 'my_cluster_name',
            :short_cluster_name    => 'the_short_cluster_name',
            :send_logs_to_logstash => true,
            :publish_host          => '127.0.0.1',
          }
        } }

        it { should contain_package('liblogstash-gelf-java').with({ :ensure => 'installed' }) }
      end
    end
  end
end
