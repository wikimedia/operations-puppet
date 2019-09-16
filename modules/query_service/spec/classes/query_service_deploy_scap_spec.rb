require_relative '../../../../rake_modules/spec_helper'

describe 'query_service::deploy::scap', :type => :class do
   before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
   end

   let(:params) { {
        :deploy_user => 'deploy-service',
        :username    => 'blazegraph',
        :package_dir => '/srv/deployment/wdqs/wdqs',
        :deploy_name => 'wdqs'
        }
   }

   context 'with systemd' do
    let(:facts) { {
        :initsystem => 'systemd',
        :lsbdistrelease => '8.7',
        :lsbdistid => 'Debian',
    } }

    it { is_expected.to contain_sudo__user('scap_deploy-service_wdqs-updater').with('user' => 'deploy-service') }
    it { is_expected.to contain_sudo__user('scap_deploy-service_wdqs-blazegraph').with('user' => 'deploy-service') }
  end
end
