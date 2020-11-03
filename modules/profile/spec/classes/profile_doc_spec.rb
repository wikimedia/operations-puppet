require_relative '../../../../rake_modules/spec_helper'

describe 'profile::doc' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        'class profile::base ( $notifications_enabled = 1 ){}
        include profile::base
        exec { "apt-get update": path => "/bin/true" }'
      end
      it { is_expected.to compile }
    end
  end
end
