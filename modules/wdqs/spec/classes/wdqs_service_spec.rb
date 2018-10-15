require 'spec_helper'

describe 'wdqs::service', :type => :class do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:params) { {
        :deploy_user => 'deploy-service',
        :deploy_mode => 'scap3',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :username => 'blazegraph',
        :config_file => 'RWStore.properties',
        :logstash_host => 'localhost',
        :logstash_json_port => 115_14,
        }
   }

   context 'with systemd' do
    let(:facts) { {
        :initsystem => 'systemd',
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
    } }

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-blazegraph.service')
      .with_content(/runBlazegraph.sh -f RWStore.properties/)
    }
  end
end
