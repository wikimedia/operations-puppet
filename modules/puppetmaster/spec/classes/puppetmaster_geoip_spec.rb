require 'spec_helper'

describe 'puppetmaster::geoip' do
    let(:pre_condition) {
        '''
        class passwords::geoip {}
        '''
    }
    it { should compile }
end
