require 'spec_helper'

describe "gallium.wikimedia.org" do

    context do
        let(:facts) { {
            :interfaces => 'eth0',
            # eqiad
            :ipaddress_eth0 => '10.64.0.1',
            # Precise
            :lsbdistrelease => '12.04',
            :lsbdistid => 'Ubuntu',
            :operatingsystem => 'Ubuntu',
        } }
        before(:each) do
            Puppet::Parser::Functions.newfunction(:generate, :type => :rvalue) { |args|
                return ''
            }
        end

        it { is_expected.to compile }
    end

end
