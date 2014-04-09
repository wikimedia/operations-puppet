require 'spec_helper'

describe 'shinken::scheduler', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-scheduler')}
    it { should contain_file('/etc/shinken/schedulerd.ini')}
    it { should contain_service('shinken-scheduler')}
end
