#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe "the query_facts function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("query_facts").should == "function_query_facts"
  end
end
