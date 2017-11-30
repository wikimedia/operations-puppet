require 'spec_helper'

describe 'puppetmaster::geoip' do
    let(:node_params) { {'site' => 'eqiad'}}
    let(:pre_condition) {
        '''
        class puppetmaster { $volatiledir="/tmp" }
        class passwords::geoip {
          $user_id="foo"
          $license_key="meh"
        }
        include ::puppetmaster
        '''
    }
    it { should compile }
end
