require 'spec_helper'

describe 'nrpe', :type => :class do
    it { should include_class('nrpe::packages') }
    it { should include_class('nrpe::service') }
end
