require 'spec_helper'

describe 'shinken::broker', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_file('/etc/shinken/daemons/brokerd.ini')}
    it { should contain_service('shinken-broker')}
end
