require 'spec_helper'

describe 'shinken::arbiter', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_file('/etc/shinken/shinken.cfg')}
    it { should contain_file('/etc/shinken/arbiters/testhost.example.com.cfg')}
    it { should contain_service('shinken-arbiter')}
end
