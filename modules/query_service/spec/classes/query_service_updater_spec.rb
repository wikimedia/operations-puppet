# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'query_service::updater', :type => :class do
  on_supported_os(WMFConfig.test_on(11, 11)).each do |_, facts|
    let(:facts) { facts }
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
         :deploy_name => 'wdqs',
         :logstash_logback_port => 11_514,
         :extra_jvm_opts => [],
         :journal => 'wikidata',
         :ensure => 'present',
         }
    }

    context 'with systemd' do
      it { is_expected.to contain_file('/lib/systemd/system/wdqs-updater.service').with_content(/runStreamingUpdater.sh -opt/) }
    end
  end
end
