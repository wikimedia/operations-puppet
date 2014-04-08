require 'spec_helper'

describe 'shinken::receiver', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-receiver')}
    it { should contain_file('/etc/shinken/receiverd.ini')}
    it { should contain_service('shinken-receiver')}
end
