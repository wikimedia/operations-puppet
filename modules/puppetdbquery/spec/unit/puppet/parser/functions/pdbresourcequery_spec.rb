#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe "the pdbresourcequery function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("pdbresourcequery").should == "function_pdbresourcequery"
  end

  it "should raise a ParseError if there is less than 1 arguments" do
    lambda { scope.function_pdbresourcequery([]) }.should( raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    lambda { scope.function_pdbresourcequery([1, 2, 3]) }.should( raise_error(Puppet::ParseError))
  end
end
