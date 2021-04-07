# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'query_service::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-blazegraph' }
   let(:params) { {
        :journal => 'wikidata',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9999,
        :config_file_name => 'RWStore.wikidata.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :deploy_name => 'wdqs',
        :use_deployed_config => false,
        :logstash_logback_port => 11_514,
        :extra_jvm_opts => [],
        :use_geospatial => false,
        :federation_user_agent => 'TEST User-Agent',
        :blazegraph_main_ns => 'wdq',
        :prefixes_file => 'prefixes.conf',
        :use_oauth => false,
        }
   }

   context 'with systemd' do
    let(:facts) { {
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
    } }

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-blazegraph.service')
      .with_content(%r{runBlazegraph.sh -f /etc/wdqs/RWStore.wikidata.properties})
    }
    it { is_expected.to contain_file('/etc/wdqs/RWStore.wikidata.properties')
      .with_content(%r{AbstractJournal.file=/srv/wdqs/wikidata.jnl})
    }
  end
end

describe 'query_service::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-blazegraph' }
   let(:params) { {
        :journal => 'wikidata',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9999,
        :config_file_name => 'RWStore.wikidata.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :deploy_name => 'wdqs',
        :use_deployed_config => true,
        :logstash_logback_port => 11_514,
        :extra_jvm_opts => [],
        :use_geospatial => false,
        :federation_user_agent => 'TEST User-Agent',
        :blazegraph_main_ns => 'wdq',
        :prefixes_file => 'prefixes.conf',
        :use_oauth => false,
        }
   }

   context 'with systemd' do
    let(:facts) { {
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
    } }

    it { is_expected.to contain_file('/lib/systemd/system/wdqs-blazegraph.service')
      .with_content(/runBlazegraph.sh -f RWStore.wikidata.properties/)
    }
  end
end

describe 'query_service::blazegraph', :type => :define do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:title) { 'wdqs-categories' }
   let(:params) { {
        :journal => 'categories',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :data_dir => '/srv/wdqs',
        :log_dir => '/var/log/wdqs',
        :port => 9090,
        :config_file_name => 'RWStore.categories.properties',
        :heap_size => '1g',
        :username => 'blazegraph',
        :deploy_name => 'wdqs',
        :use_deployed_config => false,
        :logstash_logback_port => 11_514,
        :extra_jvm_opts => [],
        :use_geospatial => true,
        :federation_user_agent => 'TEST User-Agent',
        :blazegraph_main_ns => 'wdq',
        :prefixes_file => 'prefixes.conf',
        :use_oauth => false,
        }
   }

   context 'with systemd' do
    let(:facts) { {
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
