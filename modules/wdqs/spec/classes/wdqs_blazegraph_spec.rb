require 'spec_helper'

describe 'wdqs::blazegraph', :type => :class do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:params) { {
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :endpoint => '',
        :heap_size => '1g',
        :username => 'blazegraph',
        :config_file => 'RWStore.properties',
        :logstash_host => 'localhost',
        :logstash_json_port => 11_514,
        :options => [],
        :extra_jvm_opts => [],
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
