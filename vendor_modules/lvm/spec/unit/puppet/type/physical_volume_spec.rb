# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:physical_volume) do
  before(:each) do
    @type = Puppet::Type.type(:physical_volume)
    stub_default_provider!
  end

  it 'exists' do
    Puppet::Type.type(:physical_volume).should_not be_nil
  end

  describe 'the name parameter' do
    it 'exists' do
      @type.attrclass(:name).should_not be_nil
    end

    it 'onlies allow fully qualified files' do
      -> { @type.new name: 'mypv' }.should raise_error(Puppet::Error)
    end

    it 'supports fully qualified names' do
      @type.new(name: '/my/pv')[:name].should == '/my/pv'
    end
  end

  describe "the 'ensure' parameter" do
    it 'exists' do
      @type.attrclass(:ensure).should_not be_nil
    end

    it "supports 'present' as a value" do
      with(name: '/my/pv', ensure: :present) do |resource|
        resource[:ensure].should == :present
      end
    end

    it "supports 'absent' as a value" do
      with(name: '/my/pv', ensure: :absent) do |resource|
        resource[:ensure].should == :absent
      end
    end

    it 'does not support other values' do
      specifying(name: '/my/pv', ensure: :foobar).should raise_error(Puppet::Error)
    end
  end
end
