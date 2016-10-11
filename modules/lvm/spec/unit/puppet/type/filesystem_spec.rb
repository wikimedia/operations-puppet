require 'spec_helper'

describe Puppet::Type.type(:filesystem) do
  before do
    @type = Puppet::Type.type(:filesystem)
    @valid_params = {
      :name => '/dev/myvg/mylv',
      :ensure => 'present'
    }
    stub_default_provider!
      end

  it "should exist" do
    @type.should_not be_nil
  end

  describe "the name parameter" do
    it "should exist" do
      @type.attrclass(:name).should_not be_nil
    end
    it "should only allow fully qualified files" do
      specifying(:name => 'myfs').should raise_error(Puppet::Error)
    end
    it "should support fully qualified names" do
      @type.new(:name => valid_params[:name]) do |resource|
        resource[:name].should == valid_params[:name]
      end
    end
  end

  describe "the 'ensure' parameter" do
    it "should exist" do
      @type.attrclass(:ensure).should_not be_nil
      end
    it "should support a filesystem type as a value" do
      with(valid_params)[:ensure].should == :present
      end
  end

end
