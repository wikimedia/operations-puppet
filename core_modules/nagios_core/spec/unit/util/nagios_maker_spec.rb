
require 'spec_helper'

require 'puppet/util/nagios_maker'

describe Puppet::Util::NagiosMaker do # rubocop:disable RSpec/FilePath
  context 'when creating other types' do
    let(:nagtype)  { stub('nagios type', parameters: [], namevar: :name) }
    let(:provider) { stub('provider', nagios_type: nil) }
    let(:type)     { stub('type', newparam: nil, newproperty: nil, provide: provider, desc: nil, ensurable: nil) }

    before(:each) do
      Nagios::Base.stubs(:type).with(:test).returns(nagtype)
    end

    it 'is able to create a new nagios type' do
      expect(described_class).to respond_to(:create_nagios_type)
    end

    it 'fails if it cannot find the named Naginator type' do
      Nagios::Base.stubs(:type).returns(nil)

      expect { described_class.create_nagios_type(:no_such_type) }.to raise_error(Puppet::DevError)
    end

    it "creates a new RAL type with the provided name prefixed with 'nagios_'" do
      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it 'marks the created type as ensurable' do
      type.expects(:ensurable)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it "creates a namevar parameter for the nagios type's name parameter" do
      type.expects(:newparam).with(:name, namevar: true)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it 'creates a property for all non-namevar parameters' do
      nagtype.stubs(:parameters).returns([:one, :two])

      type.expects(:newproperty).with(:one)
      type.expects(:newproperty).with(:two)
      type.expects(:newproperty).with(:target)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it 'skips parameters that start with integers' do
      nagtype.stubs(:parameters).returns(['2dcoords'.to_sym, :other])

      type.expects(:newproperty).with(:other)
      type.expects(:newproperty).with(:target)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it 'deduplicates the parameter list' do
      nagtype.stubs(:parameters).returns([:one, :one])

      type.expects(:newproperty).with(:one)
      type.expects(:newproperty).with(:target)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end

    it 'creates a target property' do
      type.expects(:newproperty).with(:target)

      Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
      described_class.create_nagios_type(:test)
    end
  end

  context 'when creating the naginator provider' do
    let(:provider) { stub('provider', nagios_type: nil) }
    let(:nagtype)  { stub('nagios type', parameters: [], namevar: :name) }
    let(:type)     { stub('type', newparam: nil, ensurable: nil, newproperty: nil, desc: nil) }

    before(:each) do
      Nagios::Base.stubs(:type).with(:test).returns(nagtype)
      Puppet::Type.stubs(:newtype).with(:nagios_test).returns(type)
    end

    it 'adds a naginator provider' do
      type.expects(:provide).with { |name, _options| name == :naginator }.returns provider

      described_class.create_nagios_type(:test)
    end

    it 'sets Puppet::Provider::Naginator as the parent class of the provider' do
      type.expects(:provide).with { |_name, options| options[:parent] == Puppet::Provider::Naginator }.returns provider

      described_class.create_nagios_type(:test)
    end

    it 'uses /etc/nagios/$name.cfg as the default target' do
      type.expects(:provide).with { |_name, options| options[:default_target] == '/etc/nagios/nagios_test.cfg' }.returns provider

      described_class.create_nagios_type(:test)
    end

    it 'triggers the lookup of the Nagios class' do
      type.expects(:provide).returns provider

      provider.expects(:nagios_type)

      described_class.create_nagios_type(:test)
    end
  end
end
