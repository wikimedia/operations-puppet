require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'
require 'yaml'

describe "slice_network_constants" do
  all_network_subnets = YAML.load_file(File.dirname(__FILE__) + "/../../data/data.yaml")['network::subnets']

  it "should exist" do
    expect(Puppet::Parser::Functions.function("slice_network_constants")).to eq "function_slice_network_constants"
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    is_expected.to run.with_params.and_raise_error(ArgumentError)
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    is_expected.to run.with_params('a', 'b', 'c').and_raise_error(ArgumentError)
  end

  # Test realm
  it "should complain about invalid realm" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    expect { scope.function_slice_network_constants(['nosuchrealm']) }.to raise_error(Puppet::ParseError)
  end

  it "should return for valid realm" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production'])
    expect(result).to be_an Array
  end

  # Test site
  it "should complain about invalid site" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    expect { scope.function_slice_network_constants(['production', { 'site' => 'nosuchsite'}])}.to raise_error(Puppet::ParseError)
  end

  it "should return for valid site" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Test sphere
  it "should complain about invalid sphere" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    expect{ scope.function_slice_network_constants(['production', { 'sphere' => 'nosuchsphere'}])}.to raise_error(Puppet::ParseError)
  end

  it "should return for valid sphere" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'sphere' => 'public'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Test AF
  it "should complain about invalid af" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    expect{ scope.function_slice_network_constants(['production', { 'af' => 'nosuchaf'}])}.to raise_error(Puppet::ParseError)
  end

  it "should return for valid af" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'af' => 'ipv6'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Multiple together
  it "should return for valid site/af" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'af' => 'ipv6'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
  it "should return for valid site/sphere" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'sphere' => 'public'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
  it "should return for valid description" do
    scope.stubs(:lookupvar).with('all_network_subnets').returns(all_network_subnets)
    result = scope.function_slice_network_constants(['production', { 'site' => 'eqiad', 'description' => 'analytics'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
end
