
require 'spec_helper'

require 'puppet/provider/naginator'

describe Puppet::Provider::Naginator do # rubocop:disable RSpec/FilePath
  let(:resource_type) { stub('resource_type', name: :nagios_test) }
  let(:klass) { Class.new(described_class) }

  before(:each) do
    klass.stubs(:resource_type).returns(resource_type)
  end

  it 'is able to look up the associated Nagios type' do
    nagios_type = mock 'nagios_type'
    nagios_type.stubs :attr_accessor
    Nagios::Base.expects(:type).with(:test).returns nagios_type

    expect(klass.nagios_type).to equal(nagios_type)
  end

  it 'uses the Nagios type to determine whether an attribute is valid' do
    nagios_type = mock 'nagios_type'
    nagios_type.stubs :attr_accessor
    Nagios::Base.expects(:type).with(:test).returns nagios_type

    nagios_type.expects(:parameters).returns [:foo, :bar]

    expect(klass).to be_valid_attr(:test, :foo)
  end

  it 'uses Naginator to parse configuration snippets' do
    parser = mock 'parser'
    parser.expects(:parse).with('my text').returns 'my instances'
    Nagios::Parser.expects(:new).returns(parser)

    expect(klass.parse('my text')).to eq('my instances')
  end

  it "joins Nagios::Base records with '\\n' when asked to convert them to text" do
    klass.expects(:header).returns "myheader\n"

    expect(klass.to_file([:one, :two])).to eq("myheader\none\ntwo")
  end

  it 'is able to prefetch instance from configuration files' do
    expect(klass).to respond_to(:prefetch)
  end

  it 'is able to generate a list of instances' do
    expect(klass).to respond_to(:instances)
  end

  it 'nevers skip records' do
    expect(klass).not_to be_skip_record('foo')
  end
end
