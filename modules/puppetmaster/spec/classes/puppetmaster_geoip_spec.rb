require 'spec_helper'

describe 'puppetmaster::geoip' do
    let(:pre_condition) {
        '''
        class passwords::geoip {}
        '''
    }
    let(:params) { {
        :puppet_volatile_dir => '/srv/volatile',
    } }
    it {
        should compile
    }
    it {
        should contain_file '/srv/volatile/GeoIP'
    }
    it {
        should_not contain_file '/GeoIP'
    }
end
