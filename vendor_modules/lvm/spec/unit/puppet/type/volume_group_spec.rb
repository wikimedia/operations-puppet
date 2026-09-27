# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:volume_group) do
  before(:each) do
    @type = Puppet::Type.type(:volume_group)
    stub_default_provider!
  end

  it 'exists' do
    Puppet::Type.type(:volume_group).should_not be_nil
  end

  describe 'the name parameter' do
    it 'exists' do
      @type.attrclass(:name).should_not be_nil
    end
  end

  describe 'the extent_size parameter' do
    it 'exists' do
      @type.attrclass(:extent_size).should_not be_nil
    end
  end

  describe "the 'ensure' parameter" do
    it 'exists' do
      @type.attrclass(:ensure).should_not be_nil
    end

    it "supports 'present' as a value" do
      with(name: 'myvg', ensure: :present) do |resource|
        resource[:ensure].should == :present
      end
    end

    it "supports 'absent' as a value" do
      with(name: 'myvg', ensure: :absent) do |resource|
        resource[:ensure].should == :absent
      end
    end

    it 'does not support other values' do
      specifying(name: 'myvg', ensure: :foobar).should raise_error(Puppet::Error)
    end
  end

  describe "the 'physical_volumes' parameter" do
    it 'exists' do
      @type.attrclass(:physical_volumes).should_not be_nil
    end

    it 'supports a single value' do
      with(name: 'myvg', physical_volumes: 'mypv') do |resource|
        resource.should(:physical_volumes).should == ['mypv']
      end
    end

    it 'supports an array' do
      with(name: 'myvg', physical_volumes: ['mypv', 'otherpv']) do |resource|
        resource.should(:physical_volumes).should == ['mypv', 'otherpv']
      end
    end
  end
end
