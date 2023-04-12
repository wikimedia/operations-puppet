require 'spec_helper'

require 'puppet/external/nagios/base'
require 'puppet/external/nagios/parser'

describe Nagios::Parser do
  include PuppetSpec::Files

  subject do
    described_class.new
  end

  let(:config) { File.new(my_fixture('define_empty_param')).read }

  it 'handles empty parameter values' do
    expect { subject.parse(config) }.not_to raise_error
  end
end
