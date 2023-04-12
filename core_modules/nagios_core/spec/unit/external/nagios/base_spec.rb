require 'spec_helper'

require 'puppet/external/nagios/base'

describe Nagios::Base do
  it 'does not turn set parameters into arrays #17871' do
    obj = described_class.create('host')
    obj.host_name = 'my_hostname'
    expect(obj.host_name).to eq('my_hostname')
  end
end
