#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe "the query_nodes function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("query_nodes").should == "function_query_nodes"
  end
end
