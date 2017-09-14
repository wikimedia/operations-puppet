require 'spec_helper'

describe 'puppetmaster::geoip' do
    let(:pre_condition) {
        '''
        class passwords::geoip {}
        class puppetmaster {
            $volatiledir = "/var/lib/puppet/volatile"
        }
        '''
    }
    it {
        should compile
    }
    it {
        should contain_file '/var/lib/puppet/volatile/GeoIP'
    }
    it {
        should.not contain_file '/GeoIP'
    }
end
