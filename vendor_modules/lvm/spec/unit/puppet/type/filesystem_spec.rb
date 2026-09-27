# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:filesystem) do
  before(:each) do
    @type = Puppet::Type.type(:filesystem)
    @valid_params = {
      name: '/dev/myvg/mylv',
      ensure: 'present'
    }
    stub_default_provider!
  end

  it 'exists' do
    @type.should_not be_nil
  end

  describe 'the name parameter' do
    it 'exists' do
      @type.attrclass(:name).should_not be_nil
    end

    it 'onlies allow fully qualified files' do
      specifying(name: 'myfs').should raise_error(Puppet::Error)
    end

    it 'supports fully qualified names' do
      @type.new(name: valid_params[:name]) do |resource|
        resource[:name].should == valid_params[:name]
      end
    end
  end

  describe "the 'ensure' parameter" do
    it 'exists' do
      @type.attrclass(:ensure).should_not be_nil
    end

    it 'supports a filesystem type as a value' do
      with(valid_params)[:ensure].should == :present
    end
  end
end
