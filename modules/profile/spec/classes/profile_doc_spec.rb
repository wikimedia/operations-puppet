require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'profile::doc' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      before(:each) {
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
        }
      }
      let(:facts) { facts }
      let(:node_params) do {
        :site => 'eqiad',
        :realm => 'production',
        :initsystem => 'systemd',
      }
      end
      let(:pre_condition) do
        'class profile::base ( $notifications_enabled = 1 ){}
        include profile::base
        exec { "apt-get update": path => "/bin/true" }'
      end
      it { should compile }
    end
  end
end
