require 'spec_helper'

describe 'wdqs::updater', :type => :class do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:params) { {
        :options => ['-opt'],
        :log_dir => '/var/log/wdqs',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :username => 'blazegraph',
        :logstash_host => 'localhost',
        :logstash_json_port => 11_514,
        :logstash_logback_port => 11_514,
        :extra_jvm_opts => [],
        }
   }

   context 'with systemd' do
    let(:facts) { {
        :initsystem => 'systemd',
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
    } }

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-updater.service').with_content(/runUpdate.sh -opt/) }
  end
end
