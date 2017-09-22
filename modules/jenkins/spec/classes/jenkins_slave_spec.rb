require 'spec_helper'

describe 'jenkins::slave' do
    let(:pre_condition) do
        """
        User {
            provider => 'useradd',
        }
        """
    end
    let(:params) { {
        :ssh_key => 'abc id-rsa',
        :user    => 'agent-username',
        :workdir => '/srv/agent-username',
    } }
    it { should compile }
end
