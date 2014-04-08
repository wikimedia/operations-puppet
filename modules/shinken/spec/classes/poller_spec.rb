require 'spec_helper'

describe 'shinken::poller', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-poller')}
    it { should contain_file('/etc/shinken/pollerd.ini')}
    it { should contain_service('shinken-poller')}
end
