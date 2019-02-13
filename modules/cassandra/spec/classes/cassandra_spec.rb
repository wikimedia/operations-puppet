require 'spec_helper'

describe 'cassandra', :type => :class do
    let(:pre_condition) { 'class { "::apt": }' }

    let(:params) { {
        :target_version => '2.2',
    } }

    let(:facts) { {
         :ipaddress => '10.0.0.1',
         :initsystem => 'systemd',
         :lsbdistrelease => '9.7',
         :lsbdistid => 'Debian',
         :operatingsystem => 'Debian',
    } }

    # check that there are no dependency cycles
    it { is_expected.to compile }

    it { is_expected.to contain_apt__repository('wikimedia-cassandra22').that_comes_before('Package[cassandra]') }
    it { is_expected.to contain_exec('apt-get update').that_comes_before('Package[cassandra]') }
end
