require 'spec_helper'

describe 'jenkins::slave' do
  on_supported_os(TEST_ON).each do |os, facts|
    context "On #{os}" do
      let(:facts) {
        facts.merge({
          :initsystem => 'systemd'
        })
      }
      let(:pre_condition) do
        """
        User {
          provider => 'useradd',
        }
        """
      end
      let(:params) { {
        :ssh_key => 'abc id-rsa',
      } }
      it { should compile }
    end
  end
end
