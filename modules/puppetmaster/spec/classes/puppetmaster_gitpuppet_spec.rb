require 'spec_helper'

describe 'puppetmaster::gitpuppet' do
    before(:each) do
        Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
            'fake_secret'
        }
    end
    it { should compile }
end
