require_relative '../../../../rake_modules/spec_helper'

describe 'jenkins::slave' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
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
