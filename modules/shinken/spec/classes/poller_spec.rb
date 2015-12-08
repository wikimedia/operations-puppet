require 'spec_helper'

describe 'shinken::poller', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_file('/etc/shinken/daemons/pollerd.ini')}
    it { should contain_service('shinken-poller')}
end
