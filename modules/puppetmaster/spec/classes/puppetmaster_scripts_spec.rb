require 'spec_helper'

describe 'puppetmaster::scripts' do
    let(:node_params) { {'site' => 'test', 'realm' => 'production'} }
    it { should compile }
end
