require 'spec_helper'

describe 'Host being both a Jenkins master and a slave' do
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
