require 'spec_helper'

describe Puppet::Type.type(:physical_volume) do
  before do
    @type = Puppet::Type.type(:physical_volume)
    stub_default_provider!
  end

  it "should exist" do
    Puppet::Type.type(:physical_volume).should_not be_nil
  end

  describe "the name parameter" do
    it "should exist" do
      @type.attrclass(:name).should_not be_nil
    end
    it "should only allow fully qualified files" do
      lambda { @type.new :name => "mypv" }.should raise_error(Puppet::Error)
    end
    it "should support fully qualified names" do
      @type.new(:name => "/my/pv")[:name].should == "/my/pv"
    end
  end

  describe "the 'ensure' parameter" do
    it "should exist" do
      @type.attrclass(:ensure).should_not be_nil
      end
    it "should support 'present' as a value" do
      with(:name => "/my/pv", :ensure => :present) do |resource|
        resource[:ensure].should == :present
        end
      end
    it "should support 'absent' as a value" do
      with(:name => "/my/pv", :ensure => :absent) do |resource|
        resource[:ensure].should == :absent
        end
      end
    it "should not support other values" do
      specifying(:name => "/my/pv", :ensure => :foobar).should raise_error(Puppet::Error)
      end
  end
end
