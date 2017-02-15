require 'spec_helper'

describe 'jenkins::slave' do
    let(:pre_condition) do
        """
        User {
            provider => 'useradd',
        }
        """
    end
    let (:params) { {
        :ssh_key => 'abc id-rsa',
    } }
    it { should compile }
end
