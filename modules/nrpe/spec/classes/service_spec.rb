require 'spec_helper'

describe 'nrpe::service', :type => :class do
    it { should contain_service('nagios-nrpe-server') }
end
