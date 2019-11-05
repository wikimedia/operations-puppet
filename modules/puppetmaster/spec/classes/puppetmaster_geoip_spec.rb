require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::geoip' do
    let(:node_params) { {'site' => 'eqiad'}}
    let(:facts) do
      {
        'lsbdistrelease' => '9.9',
        'lsbdistid' => 'Debian'
      }
    end
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
