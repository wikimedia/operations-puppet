require 'spec_helper'

describe 'network::constants', :type => :class do
    it { should contain_notify('dummy') }
end
