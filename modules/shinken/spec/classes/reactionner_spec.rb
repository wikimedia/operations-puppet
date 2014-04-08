require 'spec_helper'

describe 'shinken::reactionner', :type => :class do
    let(:node) { 'testhost.example.com' }
    let(:params) { {
        }
    }

    it { should contain_package('shinken-reactionner')}
    it { should contain_file('/etc/shinken/reactionnerd.ini')}
    it { should contain_service('shinken-reactionner')}
end
