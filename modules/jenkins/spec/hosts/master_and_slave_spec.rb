require 'spec_helper'

describe 'Host being both a Jenkins master and a slave' do
  on_supported_os(TEST_ON).each do |os, facts|
    context "On #{os}" do
      let(:facts) {
        facts.merge({
          :initsystem => 'systemd'
        })
      }
      let(:node_params) { {'cluster' => 'ci', 'site' => 'eqiad'} }
      let(:pre_condition) {
        """
        class profile::base {
          $notifications_enabled = '1'
        }
        include ::profile::base
        class { 'jenkins':
          prefix => '/jenkins',
        }
        class { 'jenkins::slave':
          ssh_key => 'fake ssh key',
        }
        """
      }
      it { should compile }
    end
  end
end
