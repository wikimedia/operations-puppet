require 'spec_helper'

describe 'Host being both a Jenkins master and a slave' do
    let(:pre_condition) {
        """
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
