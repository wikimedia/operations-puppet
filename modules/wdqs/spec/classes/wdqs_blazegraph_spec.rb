require 'spec_helper'

describe 'wdqs::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-blazegraph' }
   let(:params) { {
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9999,
        :config_file_name => 'RWStore.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :use_deployed_config => false,
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
      .with_content(%r{runBlazegraph.sh -f /etc/wdqs/RWStore.properties})
    }
    it { is_expected.to contain_file('/etc/wdqs/RWStore.properties')
      .with_content(%r{AbstractJournal.file=/srv/wdqs/wikidata.jnl})
    }
  end
end

describe 'wdqs::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-blazegraph' }
   let(:params) { {
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9999,
        :config_file_name => 'RWStore.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :use_deployed_config => true,
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

describe 'wdqs::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-categories' }
   let(:params) { {
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9090,
        :config_file_name => 'RWStore.categories.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :use_deployed_config => false,
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

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-categories.service')
      .with_content(%r{runBlazegraph.sh -f /etc/wdqs/RWStore.categories.properties})
    }
    it { is_expected.to contain_file('/lib/systemd/system/wdqs-categories.service')
      .with_content(%r{BLAZEGRAPH_CONFIG=/etc/default/wdqs-categories})
    }
    it { is_expected.to contain_file('/etc/default/wdqs-categories')
      .with_content(/PORT=9090/)
    }
    it { is_expected.to contain_file('/etc/wdqs/RWStore.categories.properties')
      .with_content(%r{AbstractJournal.file=/srv/wdqs/categories.jnl})
    }
  end
end
