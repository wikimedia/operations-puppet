require 'spec_helper'

describe "the slice_network_constants function" do
  it "should exist" do
    Puppet::Parser::Functions.function("slice_network_constants").should == "function_slice_network_constants"
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    ->{ scope.function_slice_network_constants([]) }.should(raise_error(ArgumentError))
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    ->{ scope.function_slice_network_constants(['a', 'b', 'c']) }.should(raise_error(ArgumentError))
  end

  # Test realm
  it "should complain about invalid realm" do
    ->{ scope.function_slice_network_constants(['nosuchrealm']) }.should(raise_error(ArgumentError))
  end

  it "should return for valid realm" do
    result = scope.function_slice_network_constants(['production'])
    result.should(is_a? Array)
  end

  # Test site
  it "should complain about invalid site" do
    ->{ scope.function_slice_network_constants(['production', { 'site' => 'nosuchsite'}])}.should(raise_error(ArgumentError))
  end

  it "should return for valid site" do
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad'}])
    result.should(is_a? Array)
  end

  # Test sphere
  it "should complain about invalid sphere" do
    ->{ scope.function_slice_network_constants(['production', { 'sphere' => 'nosuchsphere'}])}.should(raise_error(ArgumentError))
  end

  it "should return for valid sphere" do
    result = scope.function_slice_network_constants(['production', { 'sphere' => 'public'}])
    result.should(is_a? Array)
  end

  # Test AF
  it "should complain about invalid af" do
    ->{ scope.function_slice_network_constants(['production', { 'af' => 'nosuchaf'}])}.should(raise_error(ArgumentError))
  end

  it "should return for valid af" do
    result = scope.function_slice_network_constants(['production', { 'af' => 'ipv6'}])
    result.should(is_a? Array)
  end

  # Multiple together
  it "should return for valid site/af" do
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'af' => 'ipv6'}])
    result.should(is_a? Array)
  end
  it "should return for valid site/sphere" do
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'sphere' => 'public'}])
    result.should(is_a? Array)
  end
  it "should return for valid description" do
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'description' => 'analytics'}])
    result.should(is_a? Array)
  end
end
