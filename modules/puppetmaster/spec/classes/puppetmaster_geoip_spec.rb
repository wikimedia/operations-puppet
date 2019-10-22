require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::geoip' do
    let(:node_params) do
      {
        'site' => 'eqiad',
        'realm' => 'production'
      }
    end
    let(:facts) do
      {
        'lsbdistcodename' => 'stretch',
        'lsbdistrelease' => '9.9',
        'lsbdistid' => 'Debian',
        'puppetversion' => '5.5.10',
      }
    end
    let(:pre_condition) {
        '''
        class profile::base ($notifications_enabled = true){}
        package {"prometheus-node-exporter": ensure => installed}
        exec{"apt-get update": path => "/usr/bin" }
        include profile::base
        include profile::base::puppet
        include puppetmaster
        '''
    }
    it { should compile }
end
