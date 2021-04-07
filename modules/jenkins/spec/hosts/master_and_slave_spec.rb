require_relative '../../../../rake_modules/spec_helper'

describe 'Host being both a Jenkins master and a slave' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:node_params) { {'cluster' => 'ci', 'site' => 'eqiad'} }
      let(:pre_condition) {
        """
        class { 'jenkins':
          prefix => '/jenkins',
        }
        class { 'jenkins::slave':
          ssh_key => 'fake ssh key',
        }
        """
      }
      it { should compile }
    end
  end
end
