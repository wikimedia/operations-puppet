require 'spec_helper'

describe 'base::resolving' do
    it 'requires $::nameservers' do
        should compile.and_raise_error(
            /Variable \$::nameservers is not defined!/)
    end
end
