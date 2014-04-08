require 'spec_helper'

describe 'shinken::arbiter', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-arbiter')}
    it { should contain_file('/etc/icinga/icinga.cfg')}
    it { should contain_service('shinken-arbiter')}
end
