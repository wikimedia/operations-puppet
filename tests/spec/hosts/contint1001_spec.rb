require 'spec_helper'

describe "contint1001.wikimedia.org" do

    context do
        let(:facts) { {
            # For backup host
            :uniqueid => '1234CDEF',

            :interfaces => 'eth0,lo0',
            # eqiad
            :ipaddress_eth0 => '208.80.154.17',
            # Jessie
            :lsbdistrelease => '8.6',
            :lsbdistid => 'Debian',
            :operatingsystem => 'Debian',
            # For base::service_unit / pick_initscript
            :initsystem => 'systemd',
        } }
        before(:each) do
            Puppet::Parser::Functions.newfunction(:generate, :type => :rvalue) { |args|
                return ''
            }
        end

        it { is_expected.to compile }
    end

end
