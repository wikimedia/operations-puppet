require 'spec_helper'

describe 'shinken::broker', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-broker')}
    it { should contain_file('/etc/shinken/brokerd.ini')}
    it { should contain_service('shinken-broker')}
end
