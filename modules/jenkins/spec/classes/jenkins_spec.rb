require 'spec_helper'

describe 'jenkins' do
    let(:facts) { {
        :initsystem => 'systemd',  # For systemd::syslog
    } }
    let(:params) { {
        :prefix => '/ci',

    } }
    it { should compile }
end
