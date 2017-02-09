require 'spec_helper'

describe 'interface::add_ip6_mapped' do
    let(:title) { 'testing_resource_title' }

    let(:facts) { {
        :interfaces => 'eth0',
        :lsbdistrelease => '8.6',
        :lsbdistid=> 'Debian',
    } }
    let(:params) { {
        :interface => 'eth0',
        :ipv4_address => '192.0.2.42',
    } }

    it {
        should contain_interface__ip('testing_resource_title')
            .with_interface('eth0')
            .with_address('::192:0:2:42')
    }

end
