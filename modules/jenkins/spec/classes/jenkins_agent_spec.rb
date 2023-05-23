require_relative '../../../../rake_modules/spec_helper'

describe 'jenkins::agent' do
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
        :user    => 'jenkins-agent',
        :workdir => '/srv/jenkins-agent',
      } }
      it { should compile }
    end
  end
end
